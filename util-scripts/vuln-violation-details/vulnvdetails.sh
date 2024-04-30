#!/usr/bin/env bash
#
# Simple example to retrieve all Violations ("alerts") from StackRox Central for the default policy "Fixable Severity at least Important"
#
# Requires 'curl' and 'jq'
#

# ROX_ENDPOINT is the IP or hostname of your ACS Central
if [[ -z "${ROX_ENDPOINT}" ]]; then
    echo >&2 "ROX_ENDPOINT must be set"
    exit 1
fi

# ROX_API_TOKEN is the contents of a StackRox API token created from the UI:
#   Platform Configuration -> Integrations
#   The token needs to have RBAC permissions that, at a minimum, allow Read Access to "Alert"
if [[ -z "${ROX_API_TOKEN}" ]]; then
    echo >&2 "ROX_API_TOKEN must be set"
    exit 1
fi

# Retrieve the "slim" list version of alerts. This list does not have violation details like CVEs
#    This can be filtered for any policy, system or user. Here we are only looking for violations
#    of the "Fixable Severity at least Important" system policy
ALERTLIST=$( curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}:443/v1/alerts?query=Policy%3AFixable%20Severity%20at%20least%20Important" | jq -r '.alerts.[].id' )

# loop through the alerts, by id, to retrieve details of the policy violation
for ALERTID in ${ALERTLIST}; do
    ALERTDETAILS=$( curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}:443/v1/alerts/${ALERTID}" )

    echo "${ALERTDETAILS}" 
    echo ""
done
