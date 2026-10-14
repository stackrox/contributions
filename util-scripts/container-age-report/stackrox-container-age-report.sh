#!/usr/bin/env bash
# Report active StackRox containers by rounded age.
#
# Requirements: Bash, curl, jq, Python 3
#
# Configure the Central URL and credentials with:
#   ROX_CENTRAL_URL=https://central.example.com
#   ROX_API_TOKEN_FILE=/path/to/token
# or pass --central and --token-file. Tokens are not accepted as command-line
# arguments and are supplied to curl through a private temporary header file.
#
# Examples:
#   ./stackrox-container-age-report.sh --central https://central.example.com --token-file ~/.rox-token
#   ./stackrox-container-age-report.sh --central https://central.example.com --token-file ~/.rox-token -csv -o ages.csv
#   ./stackrox-container-age-report.sh --central https://central.example.com --token-file ~/.rox-token -html -o ages.html

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  stackrox-container-age-report.sh [options]

Output format (default: command-line table):
  -html                 Write an HTML report
  -csv                  Write CSV
  --format text|html|csv

Connection options:
  --central URL         RHACS Central URL (or set ROX_CENTRAL_URL)
  --token-file FILE     File containing a bearer token
                        (or set ROX_API_TOKEN_FILE or ROX_API_TOKEN)
  --page-size N         Pods per request, 1-1000 (default: 500)
  --insecure            Skip TLS certificate verification
  -o, --output FILE     Write output to FILE instead of stdout
  -h, --help            Show this help

Age is rounded to the nearest whole day (half days round up), then grouped:
  30-59 days, 60-90 days, and over 90 days.
Containers younger than 30 rounded days are omitted.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 2
}

FORMAT=text
OUTPUT_PATH=
PAGE_SIZE=500
INSECURE=0
CENTRAL_URL=${ROX_CENTRAL_URL:-${STACKROX_CENTRAL_URL:-}}
TOKEN=${ROX_API_TOKEN:-}
TOKEN_FILE=${ROX_API_TOKEN_FILE:-}

while (($#)); do
  case "$1" in
    -html|--html)
      FORMAT=html
      ;;
    -csv|--csv)
      FORMAT=csv
      ;;
    --format)
      (($# >= 2)) || fail '--format requires text, html, or csv'
      FORMAT=$2
      shift
      ;;
    --central|--url)
      (($# >= 2)) || fail '--central requires a URL'
      CENTRAL_URL=$2
      shift
      ;;
    --token-file)
      (($# >= 2)) || fail '--token-file requires a path'
      TOKEN_FILE=$2
      shift
      ;;
    --page-size)
      (($# >= 2)) || fail '--page-size requires a number'
      PAGE_SIZE=$2
      shift
      ;;
    --insecure|-k)
      INSECURE=1
      ;;
    -o|--output)
      (($# >= 2)) || fail '--output requires a path'
      OUTPUT_PATH=$2
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
  shift
done

case "$FORMAT" in
  text|html|csv) ;;
  *) fail "unsupported output format: $FORMAT" ;;
esac

[[ -n "$CENTRAL_URL" ]] || fail 'set ROX_CENTRAL_URL or pass --central'
[[ "$CENTRAL_URL" == http://* || "$CENTRAL_URL" == https://* ]] || fail 'Central URL must start with http:// or https://'
while [[ "$CENTRAL_URL" == */ ]]; do
  CENTRAL_URL=${CENTRAL_URL%/}
done

[[ "$PAGE_SIZE" =~ ^[0-9]+$ ]] || fail '--page-size must be an integer'
if ((PAGE_SIZE < 1 || PAGE_SIZE > 1000)); then
  fail '--page-size must be between 1 and 1000'
fi

if [[ -z "$TOKEN" && -n "$TOKEN_FILE" ]]; then
  [[ -r "$TOKEN_FILE" ]] || fail "cannot read token file: $TOKEN_FILE"
  TOKEN=$(<"$TOKEN_FILE")
fi
[[ -n "$TOKEN" ]] || fail 'set ROX_API_TOKEN or ROX_API_TOKEN_FILE, or pass --token-file'
[[ "$TOKEN" != *$'\n'* && "$TOKEN" != *$'\r'* ]] || fail 'token must not contain newline characters'

for dependency in curl jq python3; do
  command -v "$dependency" >/dev/null 2>&1 || fail "required command not found: $dependency"
done

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rox-container-age.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT
AUTH_HEADER_FILE="$TMP_DIR/auth-header"
printf 'Authorization: Bearer %s\n' "$TOKEN" > "$AUTH_HEADER_FILE"
chmod 600 "$AUTH_HEADER_FILE"

CURL_ARGS=(--silent --show-error --fail --connect-timeout 20 --max-time 300
  -H "@$AUTH_HEADER_FILE"
  -H 'Accept: application/json')
if ((INSECURE)); then
  CURL_ARGS+=(-k)
fi

RECORDS_FILE="$TMP_DIR/instances.jsonl"
CLUSTERS_FILE="$TMP_DIR/clusters.json"
DEPLOYMENTS_FILE="$TMP_DIR/deployments.jsonl"
: > "$RECORDS_FILE"
: > "$DEPLOYMENTS_FILE"

# Capture one report time for all pages so a long scan does not shift the
# reported ages as each page is read.
REPORT_EPOCH=$(date +%s)

offset=0
page_number=0
while :; do
  page_number=$((page_number + 1))
  page_file="$TMP_DIR/pods-$page_number.json"
  if ! curl "${CURL_ARGS[@]}" --get \
      --data-urlencode "pagination.limit=$PAGE_SIZE" \
      --data-urlencode "pagination.offset=$offset" \
      "$CENTRAL_URL/v1/pods" -o "$page_file"; then
    printf 'Error: request for pod page at offset %s failed; report is incomplete.\n' "$offset" >&2
    exit 1
  fi

  if ! page_count=$(jq -er 'if (.pods | type) == "array" then (.pods | length) else error("response has no pods array") end' "$page_file"); then
    printf 'Error: invalid pod response on page at offset %s.\n' "$offset" >&2
    exit 1
  fi

  jq -c '
    (.pods // [])[] as $pod
    | ($pod.liveInstances // [])[] as $instance
    | select(($instance.started // "") != "")
    | select(($instance.finished // "") == "")
    | {
        clusterId: ($pod.clusterId // ""),
        namespace: ($pod.namespace // ""),
        deploymentId: ($pod.deploymentId // ""),
        containerName: ($instance.containerName // ""),
        startedAt: $instance.started
      }
  ' "$page_file" >> "$RECORDS_FILE"

  if ((page_count < PAGE_SIZE)); then
    break
  fi
  offset=$((offset + PAGE_SIZE))
done

# Cluster names make the report easier to use. If the token can list pods but
# cannot list clusters, keep going and show the cluster IDs instead.
if ! curl "${CURL_ARGS[@]}" "$CENTRAL_URL/v1/clusters" -o "$CLUSTERS_FILE"; then
  printf 'Warning: could not retrieve cluster names; the report will show cluster IDs.\n' >&2
  printf '{"clusters":[]}\n' > "$CLUSTERS_FILE"
fi

if ! jq -e '(.clusters | type) == "array"' "$CLUSTERS_FILE" >/dev/null 2>&1; then
  printf 'Warning: cluster response was not recognized; the report will show cluster IDs.\n' >&2
  printf '{"clusters":[]}\n' > "$CLUSTERS_FILE"
fi

# Deployment metadata includes deployment labels, pod-template labels, and
# deployment annotations. The export endpoint avoids one request per deployment.
if ! curl "${CURL_ARGS[@]}" "$CENTRAL_URL/v1/export/deployments" -o "$DEPLOYMENTS_FILE"; then
  printf 'Warning: could not retrieve deployment metadata; deployment IDs will still be reported.\n' >&2
  : > "$DEPLOYMENTS_FILE"
fi

python3 - "$FORMAT" "$OUTPUT_PATH" "$RECORDS_FILE" "$CLUSTERS_FILE" "$DEPLOYMENTS_FILE" "$REPORT_EPOCH" <<'PY'
import csv
import html
import json
import math
import sys
from datetime import datetime, timezone

format_name, output_path, records_path, clusters_path, deployments_path, report_epoch = sys.argv[1:]
report_time = datetime.fromtimestamp(int(report_epoch), timezone.utc)

with open(clusters_path, encoding="utf-8") as f:
    cluster_doc = json.load(f)
cluster_names = {
    str(cluster.get("id", "")): str(cluster.get("name", ""))
    for cluster in cluster_doc.get("clusters", [])
    if cluster.get("id")
}

deployment_by_id = {}
with open(deployments_path, encoding="utf-8") as f:
    for line in f:
        if not line.strip():
            continue
        try:
            document = json.loads(line)
            deployment = document.get("result", {}).get("deployment")
            if deployment is None:
                deployment = document.get("deployment", document)
            if deployment.get("id"):
                deployment_by_id[str(deployment["id"])] = deployment
        except (ValueError, TypeError, AttributeError):
            continue

def merged_labels(*maps):
    labels = set()
    for values in maps:
        if not isinstance(values, dict):
            continue
        for key, value in values.items():
            key = str(key)
            if key.lower() == "revision":
                continue
            if value is True or str(value) == "true":
                labels.add(key)
            else:
                labels.add(f"{key}={value}")
    return sorted(labels, key=lambda label: (label.lower(), label))

def labels_cell(values):
    return ", ".join(values)

def image_name_for(deployment, container_name):
    for container in deployment.get("containers", []):
        if container.get("name") != container_name:
            continue
        image = container.get("image") or {}
        name = image.get("name") or {}
        full_name = name.get("fullName", "")
        if full_name:
            # Keep the configured repository/tag name, but never print a digest.
            return str(full_name).split("@", 1)[0]
        registry = name.get("registry", "")
        remote = name.get("remote", "")
        tag = name.get("tag", "")
        base = "/".join(part for part in (registry, remote) if part)
        if base and tag:
            return f"{base}:{tag}"
        return base or "(unavailable)"
    return "(unavailable)"

def label_inline(values):
    if not values:
        return '<span class="empty">No labels</span>'
    return f'<span class="labels">{", ".join(html.escape(str(label)) for label in values)}</span>'

rows = []
missing_or_invalid_start = 0
with open(records_path, encoding="utf-8") as f:
    for line in f:
        try:
            record = json.loads(line)
            started_raw = record.get("startedAt", "")
            started = datetime.fromisoformat(started_raw.replace("Z", "+00:00"))
            if started.tzinfo is None:
                started = started.replace(tzinfo=timezone.utc)
            age_seconds = (report_time - started.astimezone(timezone.utc)).total_seconds()
            if age_seconds < 0:
                continue
            # Round to the nearest whole day, with half days rounded upward.
            age_days = math.floor(age_seconds / 86400 + 0.5)
        except (ValueError, TypeError, AttributeError):
            missing_or_invalid_start += 1
            continue

        if age_days < 30:
            continue
        if age_days < 60:
            bucket = "30-59 days"
            bucket_order = 0
        elif age_days <= 90:
            bucket = "60-90 days"
            bucket_order = 1
        else:
            bucket = ">90 days"
            bucket_order = 2

        cluster_id = str(record.get("clusterId", ""))
        deployment_id = str(record.get("deploymentId", ""))
        deployment = deployment_by_id.get(deployment_id, {})
        deployment_labels = deployment.get("labels", {})
        pod_labels = deployment.get("podLabels", {})
        labels = merged_labels(deployment_labels, pod_labels)
        rows.append({
            "age_days": age_days,
            "age_bucket": bucket,
            "cluster": deployment.get("clusterName") or cluster_names.get(cluster_id) or cluster_id or "(unknown)",
            "namespace": str(record.get("namespace", "")),
            "image_name": image_name_for(deployment, str(record.get("containerName", ""))),
            "labels": labels_cell(labels),
            "_labels": labels,
            "_bucket_order": bucket_order,
        })

rows.sort(key=lambda row: (row["_bucket_order"], -row["age_days"], row["cluster"].lower(),
                           row["namespace"].lower(), row["image_name"].lower()))

bucket_labels = ["30-59 days", "60-90 days", ">90 days"]
counts = {label: sum(1 for row in rows if row["age_bucket"] == label) for label in bucket_labels}
fieldnames = [
    "age_days", "age_bucket", "cluster", "namespace", "image_name",
    "labels",
]
for row in rows:
    row.pop("_bucket_order", None)

def render_text():
    print("StackRox active container age report")
    print("Age: nearest whole day; bins: 30-59, 60-90, and >90 rounded days")
    for label in bucket_labels:
        print(f"{label}: {counts[label]}")
    if not rows:
        print("\nNo active containers at least 30 rounded days old.")
        return

    columns = [
        ("AGE", "age_days", 5),
        ("BUCKET", "age_bucket", 11),
        ("CLUSTER", "cluster", 22),
        ("NAMESPACE", "namespace", 22),
        ("IMAGE", "image_name", 32),
        ("LABELS", "labels", 42),
    ]
    def clip(value, width):
        value = str(value)
        return value if len(value) <= width else value[:width - 1] + "…"
    print()
    print("  ".join(title.ljust(width) for title, _, width in columns))
    print("  ".join("-" * width for _, _, width in columns))
    for row in rows:
        print("  ".join(clip(row[key], width).ljust(width) for _, key, width in columns))
    print("\nLabels combine deployment and pod-template labels, omit revision, and show true values as bare keys.")

def render_csv(stream):
    writer = csv.DictWriter(stream, fieldnames=fieldnames, extrasaction="ignore", lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)

def render_html():
    esc = html.escape
    headers = {
        "age_days": "Age (days)",
        "age_bucket": "Age group",
        "cluster": "Cluster",
        "namespace": "Namespace",
        "image_name": "Image",
        "labels": "Labels",
    }
    print("<!doctype html>")
    print('<html lang="en"><head><meta charset="utf-8">')
    print('<meta name="viewport" content="width=device-width, initial-scale=1">')
    print("<title>StackRox active container age report</title>")
    print("""<style>
      body{font:14px system-ui,sans-serif;margin:2rem;color:#202124}
      h1{font-size:1.5rem}.meta{color:#555}
      table{border-collapse:collapse;width:100%;table-layout:fixed;font-size:.85rem}
      col.age-col{width:7%}col.cluster-col{width:20%}col.namespace-col{width:20%}
      col.image-col{width:33%}col.labels-col{width:20%}
      th,td{border:1px solid #ddd;padding:.45rem;text-align:left;overflow-wrap:anywhere}
      th{background:#f3f5f7;position:sticky;top:0}
      tr:nth-child(even){background:#fafafa}
      .table-wrap{overflow-x:auto}
      details.age-section{margin:1rem 0;border:1px solid #ddd;border-radius:6px;padding:.75rem}
      details.age-section>summary{cursor:pointer;font-size:1.2rem}
      .labels{font-size:.78rem;overflow-wrap:anywhere}
      .empty{color:#777}
    </style></head><body>""")
    print("<h1>StackRox active container age report</h1>")
    print('<p class="meta">Ages are rounded to the nearest whole day, with half days rounded up. Containers under 30 rounded days are omitted.</p>')
    print('<p class="meta">Image names come from the matching container in the deployment specification; digest suffixes are omitted. Labels combine deployment and pod-template labels, omit the revision label, and show true values as bare keys.</p>')
    group_columns = [
        "age_days", "cluster", "namespace", "image_name",
    ]
    for group_index, label in enumerate(bucket_labels):
        group_rows = [row for row in rows if row["age_bucket"] == label]
        print(f'<details class="age-section" id="age-group-{group_index}"><summary>{esc(label)} <span class="meta">({len(group_rows)})</span></summary>')
        if not group_rows:
            print("<p>No containers in this age range.</p></details>")
            continue
        print('<div class="table-wrap"><table><colgroup>')
        print('<col class="age-col"><col class="cluster-col"><col class="namespace-col"><col class="image-col"><col class="labels-col">')
        print('</colgroup><thead><tr>')
        for name in group_columns:
            print(f"<th>{esc(headers[name])}</th>")
        print(f"<th>{esc(headers['labels'])}</th></tr></thead><tbody>")
        for row in group_rows:
            print("<tr>" + "".join(f"<td>{esc(str(row.get(name, '')))}</td>" for name in group_columns))
            print(f"<td>{label_inline(row['_labels'])}</td></tr>")
        print("</tbody></table></div></details>")
    if missing_or_invalid_start:
        print(f'<p class="meta">Skipped {missing_or_invalid_start} records with invalid start timestamps.</p>')
    print("</body></html>")

if output_path:
    with open(output_path, "w", encoding="utf-8", newline="") as out:
        if format_name == "csv":
            render_csv(out)
        elif format_name == "html":
            # Direct the HTML renderer to the selected output file.
            original_stdout = sys.stdout
            sys.stdout = out
            try:
                render_html()
            finally:
                sys.stdout = original_stdout
        else:
            original_stdout = sys.stdout
            sys.stdout = out
            try:
                render_text()
            finally:
                sys.stdout = original_stdout
else:
    if format_name == "csv":
        render_csv(sys.stdout)
    elif format_name == "html":
        render_html()
    else:
        render_text()
PY
