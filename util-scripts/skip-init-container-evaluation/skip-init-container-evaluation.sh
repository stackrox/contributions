#!/bin/bash
# Adds skipContainerTypes: ["INIT"] to all existing policies that don't already have it.
# This is intended for customers upgrading to 5.0+ who want to preserve the pre-5.0 behavior
# where init containers were not evaluated by policies.

set -euo pipefail

if [[ -z "${ROX_ENDPOINT:-}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN:-}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

API="https://${ROX_ENDPOINT}"
AUTH="Authorization: Bearer ${ROX_API_TOKEN}"

# Version check — require 5.0+
version=$(curl -sk -H "$AUTH" "$API/v1/metadata" | jq -r '.version')
major=$(echo "$version" | cut -d. -f1)

if [[ "$major" -lt 5 ]]; then
  echo >&2 "This script requires ACS 5.0 or later (detected: $version)"
  exit 1
fi

echo "ACS version: $version"

# List all policies
policies=$(curl -sk -H "$AUTH" "$API/v1/policies" | jq -r '.policies[].id')
total=$(echo "$policies" | wc -l | tr -d ' ')
updated=0
skipped=0

echo "Found $total policies"
echo ""
echo "This will add skipContainerTypes: [\"INIT\"] to all policies without an existing evaluation filter."
echo "This action is not easily reversible."
read -rp "Continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

for id in $policies; do
  policy=$(curl -sk -H "$AUTH" "$API/v1/policies/$id")
  name=$(echo "$policy" | jq -r '.name')

  # Skip if any evaluation filter is already configured
  existing_filter=$(echo "$policy" | jq -e '.evaluationFilter // empty' 2>/dev/null)
  if [[ -n "$existing_filter" && "$existing_filter" != "{}" ]]; then
    echo "  SKIP: \"$name\" — already has evaluation filter"
    skipped=$((skipped + 1))
    continue
  fi

  # Skip build-only policies — container type filters don't apply at build time
  lifecycle_stages=$(echo "$policy" | jq -r '.lifecycleStages[]')
  if [[ "$lifecycle_stages" == "BUILD" ]]; then
    echo "  SKIP: \"$name\" — build-only policy"
    skipped=$((skipped + 1))
    continue
  fi

  # Skip declarative (CRD-managed) policies — customers should update their CRD manifests directly
  source=$(echo "$policy" | jq -r '.source')
  if [[ "$source" == "DECLARATIVE" ]]; then
    echo "  SKIP: \"$name\" — declarative policy (update CRD directly)"
    skipped=$((skipped + 1))
    continue
  fi

  # Skip audit log and node event policies — they don't evaluate containers
  event_source=$(echo "$policy" | jq -r '.eventSource')
  if [[ "$event_source" == "AUDIT_LOG_EVENT" || "$event_source" == "NODE_EVENT" ]]; then
    echo "  SKIP: \"$name\" — $event_source policy (no container evaluation)"
    skipped=$((skipped + 1))
    continue
  fi

  # Add skipContainerTypes: ["INIT"] to the evaluation filter
  updated_policy=$(echo "$policy" | jq '.evaluationFilter = {"skipContainerTypes": ["INIT"]}')

  result=$(curl -sk -o /dev/null -w "%{http_code}" -XPUT -H "$AUTH" -H "Content-Type: application/json" \
    "$API/v1/policies/$id" --data "$updated_policy")

  if [[ "$result" == "200" ]]; then
    echo "  UPDATED: \"$name\""
    updated=$((updated + 1))
  else
    echo >&2 "  ERROR: \"$name\" — HTTP $result"
  fi
done

echo ""
echo "Done. Updated: $updated, Skipped: $skipped, Total: $total"
