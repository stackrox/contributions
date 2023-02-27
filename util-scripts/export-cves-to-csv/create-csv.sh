#! /bin/bash

set -e

VERSION="${VERSION:-v1}"

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo >&2 "usage: create-csv.sh <output filename>"
  exit 1
fi

output_file="$1"
if [[ "${VERSION}" == "v1" ]]; then
  echo '"Deployment", "Image", "CVE", "CVSS Score", "Summary", "Severity", "Component", "Version", "Fixed By", "Layer Index", "Layer Instruction"' > "${output_file}"
elif [[ "${VERSION}" == "v2" ]]; then
  echo '"Cluster Name", "Cluster Id", "Namespace", "Namespace Id","Deployment", "Image", "CVE", "CVSS Score", "Summary", "Severity", "Component", "Version", "Fixed By", "Layer Index", "Layer Instruction"' > "${output_file}"
else
  echo "Unknown version ${VERSION} detected. v1 and v2 supported"
  exit 1
fi

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

# Collect all alerts
cvss=7

res="$(curl_central "v1/alerts?query=Policy%3AFixable%20Severity%20at%20least%20Important")"

# Iterate over all deployments and get the full deployment
for deployment_id in $(echo "${res}" | jq -r .alerts[].deployment.id); do
  deployment_res="$(curl_central "v1/deployments/${deployment_id}")"
  if [[ "$(echo "${deployment_res}" | jq -rc .name)" == null ]]; then
   continue;
  fi
  
  if [[ "$(echo "${deployment_res}" | jq '.containers | length')" == "0" ]]; then
   continue;
  fi

  export deployment_name="$(echo "${deployment_res}" | jq -rc .name)"
  export namespace="$(echo "${deployment_res}" | jq -rc .namespace)"
  export namespaceId="$(echo "${deployment_res}" | jq -rc .namespaceId)"
  export clusterName="$(echo "${deployment_res}" | jq -rc .clusterName)"
  export clusterId="$(echo "${deployment_res}" | jq -rc .clusterId)"

   # Iterate over all images within the deployment and render the CSV Lines
   for image_id in $(echo "${deployment_res}" | jq -r 'select(.containers != null) | .containers[].image.id'); do
     if [[ "${image_id}" != "" ]]; then
       image_res="$(curl_central "v1/images/${image_id}" | jq -rc)" 
       if [[ "$(echo "${image_res}" | jq -rc .name)" == null ]]; then
        continue;
       fi

       image_name="$(echo "${image_res}" | jq -rc '.name.fullName')"
       export image_name
       
       # Format the CSV correctly
       if [[ "${VERSION}" == "v1" ]]; then
         echo "${image_res}" | jq -r --argjson cvss "$cvss" 'try (.metadata.v1.layers as $layers | .scan.components | sort_by(.layerIndex, .name) | .[]? | . as $component | select(.vulns != null) | .vulns[] | select(.cvss >= $cvss) | select(.fixedBy != null) | [ env.deployment_name, env.image_name, .cve, .cvss, .summary, .severity, $component.name, $component.version, .fixedBy, $component.layerIndex, ($layers[$component.layerIndex // 0].instruction + " " +$layers[$component.layerIndex // 0].value)]) | @csv' >> "${output_file}"
       else
         echo "${image_res}" | jq -r --argjson cvss "$cvss" 'try (.metadata.v1.layers as $layers | .scan.components | sort_by(.layerIndex, .name) | .[]? | . as $component | select(.vulns != null) | .vulns[] | select(.cvss >= $cvss) | select(.fixedBy != null) | [ env.clusterName, env.clusterId, env.namespace, env.namespaceId, env.deployment_name, env.image_name, .cve, .cvss, .summary, .severity, $component.name, $component.version, .fixedBy, $component.layerIndex, ($layers[$component.layerIndex // 0].instruction + " " +$layers[$component.layerIndex // 0].value)]) | @csv' >> "${output_file}"
       fi
     fi
   done
  done
