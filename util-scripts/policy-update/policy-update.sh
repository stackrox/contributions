#!/bin/bash
# Usage, ./policy-update.sh policy.json

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo >&2 "usage: policy-update.sh <input filename>"
  exit 1
fi

input_file_path="$1"

input=$(cat $PWD/$1)

echo $input | jq type
RES=$?
if [ $RES != 0 ]; then
    exit 1
fi

input_data()
{
    cat <<EOF
    $input
EOF
}


function curl_get_policy() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies?query=Policy%3A$1"
}

function curl_get_policy_details() {
    curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies/$1"
}

function curl_post_policy() {
  curl -sk -XPOST -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies" --data "$(input_data)"
}

function curl_put_policy() {
  curl -sk -XPUT -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/v1/policies/$1" --data "$(input_data)"
}

# Get policy Name from input file
name=$(echo $input | jq -r '.name')

get_response="$(curl_get_policy "${name}")"

# If no results, then create policy
if [[ "$(echo "${get_response}" | jq '.policies | length')" == "0" ]]; then
    echo "Policy With name: ${name}, does not exist. Creating new policy"
    res="$(curl_post_policy)"
    echo $res
    exit
fi

# Get policy ID from query response
id=$(echo $get_response | jq -r '.policies[0].id')
echo $id

# Compare the existing policy to the new definition
echo "Policy with name: ${name}, already exists. Comparing policy definitions"
current_policy=$(curl_get_policy_details "${id}" | jq 'del(. | .id, .lastUpdated, .policyVersion, .SORTName, .SORTLifecycleStage)' )
echo ""
echo "Current Policy:"
echo ""
echo $current_policy
echo "====================================="

# Need to strip: id, lastUpdated, policyVersion
new_policy="$(echo $input | jq 'del(. | .id, .lastUpdated, .policyVersion, .SORTName, .SORTLifecycleStage)')"
echo ""
echo "New Policy:"
echo ""
echo $new_policy
echo "====================================="

same=$(jq --argjson a "${new_policy}" --argjson b "${current_policy}" -n '($a | (.. | arrays) |= sort) as $a | ($b | (.. | arrays) |= sort) as $b | $a == $b')

echo "$same"
if [[ "$same" == "false" ]]; then
    echo "Policy changes detected, importing new policy spec"
    res=$(curl_put_policy $id)
    echo $res
else
    echo "No policy changes detected"
fi
