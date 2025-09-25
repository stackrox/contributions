#!/usr/bin/env bash
set -eoux pipefail

if [[ -z "${ROX_ENDPOINT}" ]]; then
	echo >&2 "ROX_ENDPOINT must be set"
	exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
	echo >&2 "ROX_API_TOKEN must be set"
	exit 1
fi

deployment_value=NA
deploymentname_value=NA
namespace_value=NA
clustername_value=NA
clusterid_value=NA
lock=NA

process_arg() {
    arg=$1

    key="$(echo "$arg" | cut -d "=" -f 1)"
    value="$(echo "$arg" | cut -d "=" -f 2)"
     
    if [[ "$key" == "deployment" ]]; then
        deployment_value="$value"
    elif [[ "$key" == "deploymentname" ]]; then
        deploymentname_value="$value"
    elif [[ "$key" == "namespace" ]]; then
	namespace_value="$value"
    elif [[ "$key" == "clustername" ]]; then
	clustername_value="$value"
    elif [[ "$key" == "clusterid" ]]; then
	clusterid_value="$value"
    elif [[ "$key" == "lock" ]]; then
	lock_value="$value"
    fi
}

process_args() {
    for arg in "$@"; do
        process_arg "$arg"
    done
}

get_process_baselines() {
    local json_deployments_with_processes
    json_deployments_with_processes="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deploymentswithprocessinfo" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

    if [[ "$namespace_value" != "NA" ]]; then
    	json_deployments_with_processes="$(echo "$json_deployments_with_processes" | jq --arg namespace "$namespace_value" '{deployments: [.deployments[] | select(.deployment.namespace == $namespace)]}')"
    fi
    if [[ "$deploymentname_value" != "NA" ]]; then
    	json_deployments_with_processes="$(echo "$json_deployments_with_processes" | jq --arg name "$deploymentname_value" '{deployments: [.deployments[] | select(.deployment.name == $name)]}')"
    fi
    if [[ "$deployment_value" != "NA" ]]; then
    	json_deployments_with_processes="$(echo "$json_deployments_with_processes" | jq --arg deployment "$deployment_value" '{deployments: [.deployments[] | select(.deployment.id == $deployment)]}')"
    fi
    if [[ "$clustername_value" != "NA" ]]; then
    	json_deployments_with_processes="$(echo "$json_deployments_with_processes" | jq --arg cluster "$cluster_value" '{deployments: [.deployments[] | select(.deployment.cluster == $cluster)]}')"
    fi
    if [[ "$clusterid_value" != "NA" ]]; then
    	json_deployments_with_processes="$(echo "$json_deployments_with_processes" | jq --arg clusterid "$clusterid_value" '{deployments: [.deployments[] | select(.deployment.clusterid == $cluster_id)]}')"
    fi

    echo "$json_deployments_with_processes" | jq
}

get_keys_from_deployments_with_process_info() {
    json_deployments_with_processes=$1
    
    keys="$(echo "$json_deployments_with_processes" | jq '[.deployments[] | . as $deployment | .baselineStatuses[] | {deployment_id: $deployment.deployment.id, container_name: .containerName, cluster_id: $deployment.deployment.clusterId, namespace: $deployment.deployment.namespace}]')"
    
    echo "$keys"
}

keys_to_lock_query() {
    keys=$1
    
    query='{"keys": '"$keys"', "locked": '"$lock_value"'}'
    
    echo "$query"
}

process_args $@

json_deployments_with_processes="$(get_process_baselines)"
keys="$(get_keys_from_deployments_with_process_info "$json_deployments_with_processes")"
query="$(keys_to_lock_query "$keys")"

#echo "$keys" | jq

tmpfile=$(mktemp)
echo "$query" > "$tmpfile"

process_baselines_json="$(curl --location --silent --request PUT "https://${ROX_ENDPOINT}/v1/processbaselines/lock" -k --header "Authorization: Bearer $ROX_API_TOKEN" --data @"$tmpfile")"

echo "$process_baselines_json" | jq
