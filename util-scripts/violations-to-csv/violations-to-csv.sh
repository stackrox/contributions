#! /bin/bash
# This script builds a CSV file from for the active deployments on the violations page.
# Requires ROX_ENDPOINT and ROX_API_TOKEN environment variables

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo >&2 "usage: create-csv.sh <output filename>"
  exit 1
fi

output_file="$1"
echo '"Policy", "Description", "Severity", "Cluster", "Namespace", "Deployment", "Time", "Enforcement Count", "Enforcement Action"' > "${output_file}"

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

# Collect all alerts

res="$(curl_central "v1/alerts?query=Inactive%20Deployment%3Afalse")"
echo $res

# If no results, then exist
if [[ "$(echo "${res}" | jq '.alerts | length')" == "0" ]]; then
   break
fi

# Iterate over all alerts

echo $res | jq -c -r '.alerts[]' | while IFS= read alert; do
  # Format the CSV correctly
  echo "====="
  echo $alert
  echo "====="
  echo "${alert}" | jq -r '[.policy.name, .policy.description, .policy.severity, .deployment.clusterName, .deployment.namespace, .deployment.name, .time, .enforcementCount, .enforcementAction] | @csv' >> "${output_file}"
done
