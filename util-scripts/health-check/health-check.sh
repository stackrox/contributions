#! /bin/bash

set -e

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

function get_clusters() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/clusters"
}

cluster_response=$(get_clusters)

# Loop through clusters
for cluster in $(echo "${cluster_response}" | jq -r -c '.clusters[] | @base64'); do
    _jq() {
        echo ${cluster} | base64 --decode | jq -r ${1}
    }
    cluster_name=$(_jq '.name')
    health_status=$(_jq '.healthStatus')
    sensor_health_status=$(_jq '.healthStatus.sensorHealthStatus')
    collector_health_status=$(_jq '.healthStatus.collectorHealthStatus')
    overall_health_status=$(_jq '.healthStatus.overallHealthStatus')
    last_contact=$(_jq '.healthStatus.lastContact')
    version=$(_jq '.status.sensorVersion')
    echo "Cluster: ${cluster_name}, Version = ${version}, Overall = ${overall_health_status}, Sensor = ${sensor_health_status}, Collector = ${collector_health_status}, Last Contact = ${last_contact}"
    echo ""
done