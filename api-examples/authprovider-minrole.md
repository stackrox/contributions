This is a two-stage process to add the auth provider and the minimum role with the API.<br>

this is some shell script shorthand:
```bash
OPENSHIFT_AUTH='{"id":"","name":"OpenShift","type":"openshift","config":{},"uiEndpoint":"'"${CENTRAL}"'","enabled":true}'
CURLEXEC=$( curl -s -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://${CENTRAL}/v1/authProviders" -d "$OPENSHIFT_AUTH" )
```

CENTRAL is the route hostname for your Central app
and then the min access role:
```bash
# add minimum access role
MIN_ROLE='{"previous_groups":[],"required_groups":[{"props":{"authProviderId":"'"${AUTH_ID}"'"},"roleName":"Analyst"}]}'
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://${CENTRAL}/v1/groupsbatch" -d "$MIN_ROLE"
```

here's a naive but complete script:
```bash
CENTRAL=central.example.com
CENTRAL_PASS="AdminPassForCentral"

# get an API token; not needed if already available
POLICY_JSON='{ "name": "mytoken", "role":"Admin"}'
APIURL="https://$CENTRAL/v1/apitokens/generate"
ROX_API_TOKEN=$(curl -s -k -u admin:$CENTRAL_PASS -H 'Content-Type: application/json' -X POST -d "$POLICY_JSON" "$APIURL" | jq -r '.token')

# create the openshift auth SSO
OPENSHIFT_AUTH='{"id":"","name":"OpenShift","type":"openshift","config":{},"uiEndpoint":"'"${CENTRAL}"'","enabled":true}'
CURLEXEC=$( curl -s -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://${CENTRAL}/v1/authProviders" -d "$OPENSHIFT_AUTH" )

echo $CURLEXEC

AUTH_ID=echo $CURLEXEC | jq -r '.id'

echo "Created integration with ID $AUTH_ID"
echo

# add minimum access role
MIN_ROLE='{"previous_groups":[],"required_groups":[{"props":{"authProviderId":"'"${AUTH_ID}"'"},"roleName":"Analyst"}]}'
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://${CENTRAL}/v1/groupsbatch" -d "$MIN_ROLE"
echo
```

