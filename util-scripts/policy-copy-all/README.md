# Copy All StackRox Policies

This script copies all the security policies adding the suffix `(COPY)` and excluding common OpenShift namespaces. 

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://help.stackrox.com/docs/use-the-api/#generate-an-access-token)

**Required Tools:**
* `jq` is used by this script and must be installed.  Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)

**Usage**
`./policy-copy-all.sh`

> NOTE: For additional exclusions, modify or append an object to the `exclude_ns` value.

