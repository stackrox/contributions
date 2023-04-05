# Sync StackRox Policy

This script consumes a policy definition json file and either creates or updates and existing StackRox policy of the same name if there are any changes

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/3.74/cli/getting-started-cli.html#cli-authentication_cli-getting-started)

**Required Argument:**
* `$1 = path/to/policy_definition.json`

**Required Tools:**
* `jq` is used by this script and must be installed.  Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)

**Usage**
`./policy-update.sh /policies/root-user.json`

