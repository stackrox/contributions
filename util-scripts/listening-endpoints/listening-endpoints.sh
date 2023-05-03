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
format_value=table
display_node_value="false"
control_plane_value=NA

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
    elif [[ "$key" == "format" ]]; then
	format_value="$value"
    elif [[ "$key" == "display_node" ]]; then
        display_node_value="$value"
    elif [[ "$key" == "control_plane" ]]; then
        control_plane_value="$value"
    fi
}

process_args() {
     for arg in "$@"; do
	 process_arg "$arg"
     done
}

create_pod_node_map() {

    local pods_response="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/pods" -k --header "Authorization: Bearer $ROX_API_TOKEN")"

    # Parse the JSON response using jq and loop through the pods
    for pod in $(echo "$pods_response" | jq -r '.pods[] | @base64'); do
        local pod_json="$(echo "$pod" | base64 --decode)"  # decode base64 pod JSON

        # Extract pod ID and node from the pod JSON
        local pod_id="$(echo "$pod_json" | jq -r '.id')"
	pod_id_key="$(echo "$pod_id" | tr -d "-")"
	local live_instances="$(echo "$pod_json" | jq -r '.liveInstances')"
        if [[ "$live_instances" != "null" ]]; then
	    node="$(echo "$live_instances" | jq -r '.[0].instanceId.node')"

            # Add pod ID and node to the associative array
            pod_node_map["$pod_id_key"]=$node
        fi
    done
}

get_deployments() {
    if [[ "$deployment_value" == "NA" ]]; then
        json_deployments="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deployments" -k -H "Authorization: Bearer $ROX_API_TOKEN")"
    
        if [[ "$namespace_value" != "NA" ]]; then
    	    json_deployments="$(echo "$json_deployments" | jq --arg namespace "$namespace_value" '{deployments: [.deployments[] | select(.namespace == $namespace)]}')"
        fi

        if [[ "$control_plane_value" == "control_plane_only" ]]; then
	    json_deployments="$(echo "$json_deployments" | jq '{deployments: [.deployments[] | select(.namespace == "kube-node-lease" or .namespace == "kube-public" or .namespace == "kube-system")]}')"
        fi

        if [[ "$control_plane_value" == "without_control_plane" ]]; then
	    json_deployments="$(echo "$json_deployments" | jq '{deployments: [.deployments[] | select(.namespace != "kube-node-lease" and .namespace != "kube-public" and .namespace != "kube-system")]}')"
        fi
    
        if [[ "$deploymentname_value" != "NA" ]]; then
    	    json_deployments="$(echo "$json_deployments" | jq --arg deploymentname "$deploymentname_value" '{deployments: [.deployments[] | select(.name == $deploymentname)]}')"
        fi
    
        if [[ "$clustername_value" != "NA" ]]; then
    	    json_deployments="$(echo "$json_deployments" | jq --arg clustername "$clustername_value" '{deployments: [.deployments[] | select(.cluster == $clustername)]}')"
        fi
        
        if [[ "$clusterid_value" != "NA" ]]; then
    	    json_deployments="$(echo "$json_deployments" | jq --arg clusterid "$clusterid_value" '{deployments: [.deployments[] | select(.clusterId == $clusterid)]}')"
        fi
    
        ndeployment="$(echo $json_deployments | jq '.deployments | length')"
        for ((i = 0; i < ndeployment; i = i + 1)); do
            deployments+=("$(echo "$json_deployments" | jq .deployments[$i].id | tr -d '"')")
        done
    else
        deployments=($deployment_value)
    fi
}

get_node() {
    local listening_endpoint="$1"

    podUid="$(echo $listening_endpoint | jq -r .podUid)"
    if [[ -n "$podUid" ]]; then
        pod_id_key="$(echo "$podUid" | tr -d "-")"
        node=${pod_node_map[$pod_id_key]}
    else
        node=""
    fi

    echo "$node"
}

get_listening_endpoints_for_json() {
    for deployment in ${deployments[@]}; do
        listening_endpoints="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/listening_endpoints/deployment/$deployment" -k --header "Authorization: Bearer $ROX_API_TOKEN")" || true
        if [[ "$listening_endpoints" != "" ]]; then
            nlistening_endpoints="$(echo $listening_endpoints | jq '.listeningEndpoints | length')"
    	    if [[ "$nlistening_endpoints" > 0 ]]; then
		if [[ "$display_node_value" == "true" ]]; then
		    for ((j = 0; j < nlistening_endpoints; j = j + 1)); do
		        listening_endpoint="$(echo $listening_endpoints | jq -r .listeningEndpoints[$j])"
		        node="$(get_node "$listening_endpoint")"
		        listening_endpoints="$(echo "$listening_endpoints" | jq ".listeningEndpoints[$j].node = \"$node\"")"
                    done
                fi
                echo "deployment= $deployment"
                echo $listening_endpoints | jq
                echo
    	    fi
        fi
    done
}

get_listening_endpoints_for_table() {
    table_lines=""
    
    for deployment in ${deployments[@]}; do
        listening_endpoints="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/listening_endpoints/deployment/$deployment" -k --header "Authorization: Bearer $ROX_API_TOKEN")" || true
        if [[ "$listening_endpoints" != "" ]]; then
            nlistening_endpoints="$(echo $listening_endpoints | jq '.listeningEndpoints | length')"
    
            for ((j = 0; j < nlistening_endpoints; j = j + 1)); do
                l4_proto="$(echo $listening_endpoints | jq -r .listeningEndpoints[$j].endpoint.protocol)"
                if [[ "$l4_proto" == L4_PROTOCOL_TCP ]]; then
                    proto=tcp
                elif [[ "$l4_proto" == L4_PROTOCOL_UDP ]]; then
                    proto=udp
                else
                    proto=unkown
                fi
    
                listening_endpoint="$(echo $listening_endpoints | jq -r .listeningEndpoints[$j])"
                name="$(echo $listening_endpoint | jq -r .signal.name)"
                plop_port="$(echo $listening_endpoint | jq -r .endpoint.port)"
                namespace="$(echo $listening_endpoint | jq -r .namespace)"
                clusterId="$(echo $listening_endpoint | jq -r .clusterId)"
                podId="$(echo $listening_endpoint | jq -r .podId)"
                containerName="$(echo $listening_endpoint | jq -r .containerName)"
                pid="$(echo $listening_endpoint | jq -r .signal.pid)"

                table_line=$(printf "%-20s %-9s %-7s %-7s %-15s %-40s %-55s %-20s" \
                    "$name" "$pid" "$plop_port" "$proto" "$namespace" "$clusterId" \
                    "$podId" "$containerName")

		if [[ "$display_node_value" == "true" ]]; then
                    node="$(get_node "$listening_endpoint")"
		    table_line="${table_line} $node"
                fi
                    	
    
                table_lines="${table_lines}${table_line}\n"
            done
        fi
    done
    
    echo
    header=$(printf "%-20s %-9s %-7s %-7s %-15s %-40s %-55s %-20s" \
        "Program name" "PID" "Port" "Proto" "Namespace" "clusterId" \
        "podId" "containerName")


    if [[ "$display_node_value" == "true" ]]; then
        header="${header} node"
    fi

    echo -e "$header"
    echo -e "$table_lines"

}

process_args $@

deployments=()
get_deployments
declare -A pod_node_map  # associative array to store pod ID as key and node as value
create_pod_node_map
if [[ "$format_value" == "json" ]]; then
    get_listening_endpoints_for_json
else
    get_listening_endpoints_for_table
fi

