# Sync StackRox Policy

This script consumes a policy definition json file and either creates or updates and existing StackRox policy of the same name if there are any changes

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://help.stackrox.com/docs/use-the-api/#generate-an-access-token)

**Required Argument:**
* `$1 = path/to/policy_definition.json`

**Usage**
`./policy-update.sh /policies/root-user.json`

