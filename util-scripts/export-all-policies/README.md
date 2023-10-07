# Export all policies

This script uses the StackRox API to export all policies (both user defined and system) to a JSON file.

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/4.2/cli/using-the-roxctl-cli.html#authenticating-by-using-the-roxctl-cli_using-roxctl-cli)

**Required Tools:**
* `jq` is used by this script and must be installed.  Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)

**Usage**
`./export-all-policies.sh <output filename>`
