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
    fi
}

process_args() {
     for arg in "$@"; do
	 process_arg "$arg"
     done
}

process_args $@

if [[ "$deployment_value" == "NA" ]]; then
    json_deployments="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/deployments" -k -H "Authorization: Bearer $ROX_API_TOKEN")"

    if [[ "$namespace_value" != "NA" ]]; then
	json_deployments="$(echo "$json_deployments" | jq --arg namespace "$namespace_value" '{deployments: [.deployments[] | select(.namespace == $namespace)]}')"
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
    deployments=()
    for ((i = 0; i < ndeployment; i = i + 1)); do
        deployments+=("$(echo "$json_deployments" | jq .deployments[$i].id | tr -d '"')")
    done
else
    deployments=($deployment_value)
fi


netstat_lines=""

for deployment in ${deployments[@]}; do
    listening_endpoints="$(curl --location --silent --request GET "https://${ROX_ENDPOINT}/v1/listening_endpoints/deployment/$deployment" -k --header "Authorization: Bearer $ROX_API_TOKEN")" || true
    if [[ "$listening_endpoints" != "" ]]; then
        nlistening_endpoints="$(echo $listening_endpoints | jq '.listeningEndpoints | length')"
	if [[ "$nlistening_endpoints" > 0 ]]; then
	    if [[ "$format_value" == "json" ]]; then
                echo "deployment= $deployment"
                echo $listening_endpoints | jq
                echo
            fi	
	fi

        for ((j = 0; j < nlistening_endpoints; j = j + 1)); do
            l4_proto="$(echo $listening_endpoints | jq .listeningEndpoints[$j].endpoint.protocol | tr -d '"')"
            if [[ "$l4_proto" == L4_PROTOCOL_TCP ]]; then
                proto=tcp
            elif [[ "$l4_proto" == L4_PROTOCOL_UDP ]]; then
                proto=udp
            else
               proto=unkown
            fi

            name="$(echo $listening_endpoints | jq .listeningEndpoints[$j].signal.name | tr -d '"')"
            plop_port="$(echo $listening_endpoints | jq .listeningEndpoints[$j].endpoint.port | tr -d '"')"
            namespace="$(echo $listening_endpoints | jq .listeningEndpoints[$j].namespace | tr -d '"')"
            clusterId="$(echo $listening_endpoints | jq .listeningEndpoints[$j].clusterId | tr -d '"')"
            podId="$(echo $listening_endpoints | jq .listeningEndpoints[$j].podId | tr -d '"')"
            containerName="$(echo $listening_endpoints | jq .listeningEndpoints[$j].containerName | tr -d '"')"
            pid="$(echo $listening_endpoints | jq .listeningEndpoints[$j].signal.pid | tr -d '"')"

            netstat_line=$(printf "%-20s %-9s %-7s %-7s %-15s %-40s %-55s %-20s" \
                "$name" "$pid" "$plop_port" "$proto" "$namespace" "$clusterId" \
                "$podId" "$containerName")

            netstat_lines="${netstat_lines}${netstat_line}\n"
        done
    fi
done

echo
if [[ "$format_value" == "table" ]]; then
    header=$(printf "%-20s %-9s %-7s %-7s %-15s %-40s %-55s %-20s\n" \
        "Program name" "PID" "Port" "Proto" "Namespace" "clusterId" \
        "podId" "containerName")

    echo -e "$header"
    echo -e "$netstat_lines"
fi
