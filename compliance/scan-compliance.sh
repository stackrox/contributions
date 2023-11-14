#! /bin/bash

set -euo pipefail

if [[ -z $ROX_API_TOKEN ]]; then
    echo "ROX_API_TOKEN needs to be set" 1>&2
    exit 1
fi

if [[ -z "$ROX_ENDPOINT" ]]; then
    echo "ROX_ENDPOINT needs to be set" 1>&2
    exit 1
fi

if [ ! -x "$(which jq)" ]; then
    echo "jq is a required for this script to work correctly" 1>&2
    exit 1
fi

function roxcurl() {
    curl -sk -H "Authorization: Bearer $ROX_API_TOKEN" "$@"
}

cluster_ids=$(roxcurl "$ROX_ENDPOINT/v1/clusters" | jq -r .clusters[].id)
for cluster in $cluster_ids; do
    echo "Triggering compliance run for cluster $cluster"
    runs=$(roxcurl "$ROX_ENDPOINT/v1/compliancemanagement/runs" -X POST -d '{ "selection": { "cluster_id": "'"$cluster"'", "standard_id": "*" } }')
    run_ids=$(jq -r .startedRuns[].id <<< "$runs")
    num_runs=$(jq '.startedRuns | length' <<< "$runs")
    while true; do
        size="$num_runs"
        for run_id in $run_ids; do
            run_status=$(roxcurl "$ROX_ENDPOINT/v1/compliancemanagement/runstatuses" --data-urlencode "run_ids=$run_id" | jq -r .runs[0])
            run_state=$(jq -r .state <<< "$run_status")
            standard=$(jq -r .standardId <<< "$run_status")
            echo "Run $run_id for cluster $cluster and standard $standard has state $run_state"
            if [[ "$run_state" != "READY" ]]; then
                size=$(( size - 1))
            fi
        done
        if [[ "$size" == 0 ]]; then
            echo "Compliance for cluster $cluster has completed"
            break
        fi
        sleep 5
    done
done
