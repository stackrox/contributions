#!/bin/bash

# Purpose: outputs policy metadata to CSV (a file named "policies.csv")
# Requires: curl, jq
# Requires: $ROX_API_TOKEN = contains an API token with the following permissions:
#   Policy (read) - for example a token with the StackRox 'Analyst' role
# Requires: $ROX_ENDPOINT = hostname/address of StackRox Central (:port if not 443)

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "Environment variable ROX_ENDPOINT must be set"
  echo >&2 "export ROX_ENDPOINT=stackrox.example.com"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "Environment variable ROX_API_TOKEN must be set"
  echo >&2 "export ROX_API_TOKEN=$(cat token-file)"
  exit 1
fi

if ! [[ -x "$(command -v curl)" ]]; then
  echo >&2 "curl does not exist or is not in the PATH"
  exit 1
fi

if ! [[ -x "$(command -v jq)" ]]; then
  echo >&2 "jq does not exist or is not in the PATH"
  exit 1
fi

# Name of output file
output_file="policies.csv"
if [[ -f "$output_file" ]]; then
  rm "$output_file"
fi
echo "Name,Description,LifecycleStages,Severity,Disabled,Rationale,Remediation,Categories,Notifiers,ID" > "$output_file"

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

policies_output=0

policies=$(curl_central "v1/policies" | jq -r '.policies[] | .id')
for policy_id in $policies
do
  #echo "$policy_id"
  policy_details=$(curl_central "v1/policies/$policy_id")

  #echo "$policy_details"
  echo "$policy_details" | jq -r '{name: .name, description: .description, lifecycleStages: (.lifecycleStages | join("|")),
  severity: .severity, disabled: .disabled, rationale: .rationale, remediation: .remediation, categories: (.categories | join("|")),
  notifiers: (.notifiers | join("|")), id: .id}
  | [.name, .description, .lifecycleStages, .severity, .disabled, .rationale, .remediation, .categories, .notifiers, .id]
  | @csv' >> "$output_file"

  policies_output=$((policies_output + 1))
done

echo "$policies_output policies were written to $output_file."
