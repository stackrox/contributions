#! /bin/bash
# This script is designed to report on container images that use a specific UBI version. It is designed to be used
# with a policy that creates violations for specific versions of the `redhat-release` package.

# To use this image, set ROX_ENDPOINT to the ACS central instance and set ROX_API_TOKEN
# to an ACS 'admin' token created.

# e.g. export ROX_ENDPOINT=central-acs-central.apps.cluster1.example.com:443
# export ROX_API_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6Imp3dGsw...
# ./ubi-versions.sh images.csv

set -e

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo >&2 "usage: ubi-versions.sh <output filename>"
  exit 1
fi

output_file="$1"
echo '"Cluster Name", "Namespace", "Deployment", "Image", "UBI version"' > "${output_file}"

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

# Collect all alerts
res="$(curl_central "v1/alerts?query=Policy%3AUBI%20version%20compliance")"

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
  export clusterName="$(echo "${deployment_res}" | jq -rc .clusterName)"

   # Iterate over all images within the deployment and render the CSV Lines
   for image_id in $(echo "${deployment_res}" | jq -r 'select(.containers != null) | .containers[].image.id'); do
     if [[ "${image_id}" != "" ]]; then
       image_res="$(curl_central "v1/images/${image_id}" | jq -rc)"
       if [[ "$(echo "${image_res}" | jq -rc .name)" == null ]]; then
        continue;
       fi

       image_name="$(echo "${image_res}" | jq -rc '.name.fullName')"
       export image_name

       # find the redhat-release version and format lines
       export ubi_version="$(echo  "${image_res}" | jq '.scan.components[] | select(.name=="redhat-release") | .version'| grep -o '[0-9]\.[0-9]\+' | head -1 )"
       echo "${clusterName},${namespace},${deployment_name},${image_name},${ubi_version}" >> "${output_file}"
     fi
   done
  done
