# Violations to CSV 

This script uses the StackRox API to export all of the active deployments on the violations page to a CSV file.

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/3.74/cli/getting-started-cli.html#cli-authentication_cli-getting-started)

**Required Argument:**
* `$1 = path/to/output_file.csv`

**Usage**
`./violations-to-csv.sh /tmp/output.csv`

