#!/bin/bash

# Purpose: clone all the system policies adding the system namespaces to scope exclusions
# Requires:
# - curl, jq
# - $ROX_API_TOKEN = contains an API token with the following permissions:
#     Policy (read) - for example a token with the StackRox 'Analyst' role
# - $ROX_ENDPOINT = hostname/address of StackRox Central (:port if not 443)
# - Update the exclude_ns variable to add/remove namespaces from the exclusion
# Actions:
# - Extract all system policies
# - Copy each policy
# - Add suffix "(COPY)" to each copied policy
# - Add system namespaces to scope exclusions in each policy
# - Create a new policy from the copy 
# - Update the original policy to disable it

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "Environment variable ROX_ENDPOINT must be set"
  echo >&2 "export ROX_ENDPOINT=stackrox.example.com"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "Environment variable ROX_API_TOKEN must be set"
  echo >&2 "export ROX_API_TOKEN=$(cat token-file)"
  exit 1
fi

if ! [[ -x "$(command -v curl)" ]]; then
  echo >&2 "curl does not exist or is not in the PATH"
  exit 1
fi

if ! [[ -x "$(command -v jq)" ]]; then
  echo >&2 "jq does not exist or is not in the PATH"
  exit 1
fi

#  Definition of the system namespaces to be excluded
#  Add another object to include additional namespaces
exclude_ns='{
  "name": "Do not alert on system namespaces",
  "deployment": {
    "name": "",
    "scope": {
      "cluster": "",
      "namespace": "^kube.*|^openshift.*|^redhat.*|^istio.*|^rhacs-operator.*|^stackrox.*",
      "label": null
    }
  },
  "image": null,
  "expiration": null
}'

## Optional system namespaces in OpenShift
#{
#  "name": "Do not alert on system namespaces",
#  "deployment": {
#    "name": "",
#    "scope": {
#      "cluster": "",
#      "namespace": "^3scale$|^amq$|^dm$|^hive$|^local-cluster$|^open-cluster-management.*",
#      "label": null
#    }
#  },
#  "image": null,
#  "expiration": null
#}'


#  Suffix to be added to the cloned policy
policy_name_suffix='(COPY)'

#  Function to interact with the API using curl
function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

function curl_get_policy_details() {
    curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies/$1"
}

function curl_post_policy() {
  curl -sk -XPOST -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies" --data "$1"

}

function curl_put_policy() {
  curl -sk -XPUT -H "Authorization: Bearer ${ROX_API_TOKEN}" \
    "https://${ROX_ENDPOINT}/v1/policies/$1" --data "$2"
}

policies_output=0
policies=$(curl_central "v1/policies" | jq -r '.policies[] | .id')
for policy_id in $policies
do
  echo
  echo "Processing Policy: $policy_id"
  echo "======================================================"

  current_policy=$(curl_get_policy_details "${policy_id}" | jq 'del(. | .id, .lastUpdated, .policyVersion, .SORTName, .SORTLifecycleStage)' )

  policy_name=$( echo $current_policy | jq -r '.name' )

  echo "$policy_name | grep $policy_name_suffix"

  if echo $policy_name | grep "$policy_name_suffix" &>/dev/null
  then
    continue
  fi

  #  Set current policy to disabled
  updated_policy=$( echo $current_policy | jq ".disabled = true" )
  #  Add suffix to the name of the clone and the exclusions
  new_policy=$( echo $current_policy | jq -c ".exclusions += [$exclude_ns] | .name = \"$policy_name $policy_name_suffix\"" )

  echo "Creating a new policy from the copy"
  res=$( curl_post_policy "$new_policy" )
  if echo "$res" | grep error &>/dev/null
  then
    echo "Creation error: $res"
    continue
  else
    echo "Disable the current policy"
    res=$(curl_put_policy $policy_id "$updated_policy")
    if [ "$res" == "{}" ]
    then
      policies_output=$((policies_output + 1))
    else
      echo "Update error: $res"
    fi
  fi

done

echo
echo "$policies_output policies were cloned."

