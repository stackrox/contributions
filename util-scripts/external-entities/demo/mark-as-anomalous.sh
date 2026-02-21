#!/usr/bin/env bash
set -eoux pipefail

ROX_ENDPOINT=${1:-localhost:8000}

deploymentname=${2:-external-destination-source-1}

json_deployments="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deployments" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

json_deployments="$(echo "$json_deployments" | jq --arg deploymentname "$deploymentname" '{deployments: [.deployments[] | select(.name == $deploymentname)]}')"
deployment="$(echo "$json_deployments" | jq --arg deploymentname "$deploymentname" '{deployments: [.deployments[] | select(.name == $deploymentname)]}' | jq -r .deployments[0].id)"

echo "json_deployments= $deployment"

json_status="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/networkbaseline/${deployment}/status/external" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

echo "$json_status" | jq

echo
echo
echo
echo

json_new_status="$(echo "$json_status" | jq -c '.anomalous |= map(.status = (if .status == "ANOMALOUS" then "BASELINE" else .status end))')"


echo "$json_new_status" | jq

#cidr_json='{"entity": {"cidr": "'"$cidr_block"'", "name": "'"$cidr_name"'", "id": ""}}'

#create_cidr_block_response_json="$(curl --location --silent --request POST --data "$cidr_json" "https://${ROX_ENDPOINT}/v1/networkgraph/cluster/$cluster_id/externalentities" -k --header "Authorization: Bearer $ROX_API_TOKEN")"

echo
echo
echo
echo
echo "Setting new status"
curl --location --silent --request POST --data "$json_new_status" "https://${ROX_ENDPOINT}/v1/networkbaseline/${deployment}/peers" -k --header "Authorization: Bearer $ROX_API_TOKEN"

echo
echo
echo
echo

echo "Checking the new status"
json_updated_status="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/networkbaseline/${deployment}/status/external" -k -H "Authorization: Bearer $ROX_API_TOKEN")"


echo "$json_updated_status" | jq
