# StackRox Cluster Health Check

This script reports on the health of all of the attached StackRox Secured Clusters

**Required Environment Vars:**

* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/3.74/cli/getting-started-cli.html#cli-authentication_cli-getting-started)

**Required Tools:**

* `jq` is used by this script and must be installed.  Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)
* `base64` is used for encoding and decoding strings

**Usage**
`./health-check.sh`

**Example Output**

```bash
Cluster: logan-support-1, Version = 3.0.57.2, Overall = HEALTHY, Sensor = HEALTHY, Collector = HEALTHY, Last Contact = 2021-04-09T00:44:18.076583Z

Cluster: cluster2, Version = 3.0.56.0, Overall = UNHEALTHY, Sensor = HEALTHY, Collector = DEGRADED, Last Contact = 2021-04-09T00:44:18.076583Z
```
