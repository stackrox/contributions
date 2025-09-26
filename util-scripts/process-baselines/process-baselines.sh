#!/usr/bin/env bash
set -eou pipefail

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
created_value=NA
lock_value=NA

nset=0

process_arg() {
    arg=$1

    key="$(echo "$arg" | cut -d "=" -f 1)"
    value="$(echo "$arg" | cut -d "=" -f 2)"
     
    if [[ "$key" == "deployment" ]]; then
        deployment_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "deploymentname" ]]; then
        deploymentname_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "namespace" ]]; then
	namespace_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "clustername" ]]; then
	clustername_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "clusterid" ]]; then
	clusterid_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "created" ]]; then
        created_value="$value"
        nset=$((nset + 1))
        return 0
    elif [[ "$key" == "lock" ]]; then
        # nset represents the number of options set other than lock
	lock_value="$value"
        return 0
    fi

    echo "Warning: Unknown option $key"
}

process_args() {
    for arg in "$@"; do
        process_arg "$arg"
    done

    if [[ "$nset" == 0 ]]; then
        echo "Must set at least one option other than lock"
        exit 1
    fi
}

get_process_baselines() {
    local offset=0
    local limit=1000
    local all_deployments="[]"
    local json_deployments_with_processes
    local current_page_deployments
    local current_page_count

    while true; do
        json_deployments_with_processes="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deploymentswithprocessinfo?pagination.offset=${offset}&pagination.limit=${limit}" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

        current_page_deployments="$(echo "$json_deployments_with_processes" | jq '.deployments')"

        current_page_count="$(echo "$current_page_deployments" | jq 'length')"

        if [[ "$current_page_count" -gt 0 ]]; then
            all_deployments="$(echo "$all_deployments" | jq --argjson new_items "$current_page_deployments" '. + $new_items')"
            offset=$((offset + current_page_count))
        fi

        if [[ "$current_page_count" -lt "$limit" ]]; then
            break
        fi
    done

    local final_json_deployments="$(echo "$all_deployments" | jq '{deployments: .}')"

    if [[ "$namespace_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg namespace "$namespace_value" '{deployments: [.deployments[] | select(.deployment.namespace == $namespace)]}')"
    fi
    if [[ "$deploymentname_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg name "$deploymentname_value" '{deployments: [.deployments[] | select(.deployment.name == $name)]}')"
    fi
    if [[ "$deployment_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg deployment "$deployment_value" '{deployments: [.deployments[] | select(.deployment.id == $deployment)]}')"
    fi
    if [[ "$clustername_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg cluster "$clustername_value" '{deployments: [.deployments[] | select(.deployment.cluster == $cluster)]}')"
    fi
    if [[ "$clusterid_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg clusterid "$clusterid_value" '{deployments: [.deployments[] | select(.deployment.clusterid == $clusterid)]}')"
    fi
    if [[ "$created_value" != "NA" ]]; then
        final_json_deployments="$(echo "$final_json_deployments" | jq --arg created "$created_value" '{deployments: [.deployments[] | select(.deployment.created > $created)]}')"
    fi

    echo "$final_json_deployments" | jq
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

if [[ "$lock_value" == "NA" ]]; then
    echo "Must specify a value for lock. It must be either true or false"
    exit 1
fi

json_deployments_with_processes="$(get_process_baselines)"
keys="$(get_keys_from_deployments_with_process_info "$json_deployments_with_processes")"

lock_batch_size=1000

total_keys=$(echo "$keys" | jq 'length')

num_batches=$(( (total_keys + lock_batch_size - 1) / lock_batch_size ))

for ((i=0; i<num_batches; i++)); do
    offset=$((i * lock_batch_size))

    batch_keys="$(echo "$keys" | jq --argjson offset "$offset" --argjson limit "$lock_batch_size" '.[$offset:$offset+$limit]')"

    query='{"keys": '"$batch_keys"', "locked": '"$lock_value"'}'

    tmpfile=$(mktemp)
    echo "$query" > "$tmpfile"

    echo "Processing batch $((i+1)) of $num_batches with offset $offset"
    process_baselines_json="$(curl --location --silent --request PUT "https://${ROX_ENDPOINT}/v1/processbaselines/lock" -k --header "Authorization: Bearer $ROX_API_TOKEN" --data @"$tmpfile")"

    echo "$process_baselines_json" | jq

    rm "$tmpfile"
done
