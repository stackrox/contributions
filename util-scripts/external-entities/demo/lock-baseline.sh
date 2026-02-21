#!/usr/bin/env bash
set -eou pipefail

ROX_ENDPOINT=${1:-localhost:8000}

deploymentname=${2:-external-destination-source-1}

json_deployments="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deployments" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

json_deployments="$(echo "$json_deployments" | jq --arg deploymentname "$deploymentname" '{deployments: [.deployments[] | select(.name == $deploymentname)]}')"
deployment="$(echo "$json_deployments" | jq --arg deploymentname "$deploymentname" '{deployments: [.deployments[] | select(.name == $deploymentname)]}' | jq -r .deployments[0].id)"

echo "json_deployments= $deployment"

json_status="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/networkbaseline/${deployment}/status/external" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

echo "$json_status" | jq


json_status="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/networkbaseline/${deployment}/lock" -k -H "Authorization: Bearer $ROX_API_TOKEN")"
