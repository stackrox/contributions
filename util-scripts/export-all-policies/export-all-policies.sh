#!/bin/bash

# Purpose: Export all policies to JSON
# Requires:
# - curl, jq
# - $ROX_API_TOKEN = contains an API token with the following permissions:
#     Policy (read) - for example a token with the StackRox 'Analyst' role
# - $ROX_ENDPOINT = hostname/address of StackRox Central (:port if not 443)
# Actions:
# - Exports all policies from ACS to JSON.

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

if [[ -z "$1" ]]; then
  echo >&2 "usage: export-all-policies.sh <output filename> "
  exit 1
fi
output_file="$1"


policies=$(curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies" | jq -r '[.policies[].id] | @csv')
curl -sk -X POST -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies/export" --data-raw "{\"policyIds\":[${policies}]}" | jq -r . > "${output_file}"
