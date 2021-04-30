#!/bin/bash

# Purpose: Dump component name and version to CSV (along with cluster, namespace, deployment and image names)
# Requires: curl, jq
# Requires: $ROX_API_TOKEN = contains an API token with at least the following permissions:
#   Cluster (read), Deployment (read), Image (read)
# Requires: $ROX_ENDPOINT = hostname/address of Central (:port if not 443)
# Notes:
#   1) /v1/deployments?query=Cluster:\"$clusterName\" has a limit of 1,000
#     deployments per page. This script will paginate, and the parameters can be
#     tuned for any environment.
#   2) Tested with StackRox 3.0.56.1
# TODOs:
#   1) add parameters for the ROX_API_TOKEN as --token or --token-file
#   2) add parameters for ROX_ENDPOINT as --endpoint or -e
#   3) add parameters for pagination
#   4) add parameters for cluster and namespace
# References:
#   https://help.stackrox.com/docs/use-the-api/
#   https://help.stackrox.com/docs/manage-user-access/manage-role-based-access-control/

IFS=$'\n'	# make newlines the only separator to allow for cluster names with spaces

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo >&2 "usage: component_details.sh <output filename>"
  exit 1
fi

outputFile="$1"
echo "clusterName,namespace,deploymentName,imageName,componentName,componentVersion" > "${outputFile}"

totalImagesReported=0

# Iterate clusters - alternatively hardcode the clusterId or name as a parameter
clusters=$(curl_central "v1/clusters" | jq -c '.clusters[] | {name, id}')
for cluster in $clusters
do
  clusterName=$(echo "$cluster" | jq -r '.name')
  export clusterName
  echo "Iterating cluster: $clusterName"

  # Get the deployments for the cluster
  # for help with pagination refer to https://help.stackrox.com/docs/use-the-api/#pagination
  pagingCounter=0 # counter for records in current page
  paginationLimit=100
  paginationOffset=0
  deployments=$(curl_central "v1/deployments?query=Cluster:\"$clusterName\"&pagination.limit=$paginationLimit&pagination.offset=$paginationOffset" \
    | jq -c '.deployments[] | {id, name, clusterId, namespace}')
  while [[ -n $deployments ]]
  do
    #echo $deployments
    echo "There are $(echo "$deployments" | jq -c | wc -l | tr -d '[:blank:]') deployments in this page for cluster $clusterName."

    # reset the counter for this page
    pagingCounter=0

    # Iterate the deployments
    for deployment in $deployments
    do
      #echo
      #echo
      #echo "Deployment result:"
      #echo "$deployment"

      # increment the paging counter
      pagingCounter=$((pagingCounter+1))
      #echo "pagingCounter = $pagingCounter"

      if [[ $(echo "${deployment}" | jq -rc .name) == null ]]; then
        continue;
      fi

      deploymentName=$(echo "$deployment" | jq -r '.name')
      export deploymentName
      deploymentId=$(echo "$deployment" | jq -r '.id')
      namespace=$(echo "$deployment" | jq -r '.namespace')
      export namespace

      echo $'\t'"Iterating deployment $deploymentName"

      deploymentDetails=$(curl_central "v1/deployments/${deploymentId}")
      #echo "$deploymentDetails"
      if [[ "$(echo "${deploymentDetails}" | jq -rc .name)" == null ]]; then
        continue;
      fi
      if [[ "$(echo "${deploymentDetails}" | jq '.containers | length')" == "0" ]]; then
        continue;
      fi

      # Iterate over all images within the deployment and render the CSV Lines
      for imageId in $(echo "${deploymentDetails}" | jq -r 'select(.containers != null) | .containers[].image.id'); do
        if [[ "${imageId}" != "" ]]; then
          image="$(curl_central "v1/images/${imageId}" | jq -rc)"
          if [[ "$(echo "${image}" | jq -rc .name)" == null ]]; then
            continue;
          fi

          imageName=$(echo "${image}" | jq -rc '.name.fullName')
          export imageName
          echo $'\t\t'"Iterating image $imageName"

          #debug
          #echo
          #echo
          #echo "Image result:"
          #echo $image

          # Format the CSV correctly
          echo "${image}" | jq -r '(.metadata.v1.layers as $layers | .scan.components | sort_by(.layerIndex, .name) | .[] | . as $component | [ env.clusterName, env.namespace, env.deploymentName, env.imageName, $component.name, $component.version ]) | @csv' >> "${outputFile}"

          totalImagesReported=$((totalImagesReported + 1))
        fi
      done

    done # ends for deployment in $deployments

    paginationOffset=$((paginationOffset + pagingCounter))
    #echo "paginationOffset = $paginationOffset"
    deployments=$(curl_central "v1/deployments?query=Cluster:\"$clusterName\"&pagination.limit=$paginationLimit&pagination.offset=$paginationOffset" \
      | jq -c '.deployments[] | {id, name, clusterId, namespace}')
  done # ends while for paging
done # ends for cluster in $clusters

echo "Script complete. A total of $totalImagesReported images have component details included in $outputFile."
