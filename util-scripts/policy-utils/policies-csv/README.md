# Output StackRox policy metadata as CSV

This script outputs the following policy metadata to CSV:
Name, Description, LifecycleStages, Severity, Disabled, Rationale, Remediation, Categories, Notifiers, ID

Refer to https://help.stackrox.com/docs/manage-security-policies/ and https://help.stackrox.com/docs/use-the-api/
for information on policies and working with the API.

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox Central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://help.stackrox.com/docs/use-the-api/#generate-an-access-token). Can be exported by running: export ROX_API_TOKEN=$(cat token-file)

**Required Tools:**
* `jq` is used by this script for parsing the policy JSON from the API. Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)
* `curl` is used by this script to connect to the StackRox Central API. curl should be installed with the OS.

**Output:**
* The script will output (overwrite) a file named "policies.csv" which is editable from within the script.

**Usage:**
`./policies-csv.sh`
