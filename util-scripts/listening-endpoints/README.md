# Listening Endpoints

This script reports the listening endpoints in the clusters and what processes are listening on them.

**Required Environment Vars:**

* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/3.74/cli/getting-started-cli.html#cli-authentication_cli-getting-started)

**Required Tools:**

* `jq` is used by this script and must be installed.  Installation instructions for various platforms can be found [here](https://stedolan.github.io/jq/download/)

**Usage:**
All of the command-line parameters are optional. The default is to output all listening endpoints in all clusters in a tabular format. The options can be used in any combination.
`./listening_endpoints.sh deployment=<deployment_id> deploymentname=<deploymentname> namespace=<namespace> clustername=<clustername> clusterid=<clusterid> format=<format>`

"format" can be json or table. The default is table.

"deployment" can be used to get the listening endpoints for a specific deployment_id. This is no different than the regular API.

"deployment_name" can be more convenient as you only need to know the name of the deployment (E.g. stackrox) rather than looking up the deployment_id for the deployment.
If using this option, you might also want to specify the namespace and clustername/cluster_id.

"namespace" can be used to look up all listening endpoints for a namespace, not just deployment. If you use this option you might also want to specify the clustername/clusterid.

"clustername" can be used to look up all listening endpoints in a cluster by its name. E.g "production", or "dev".

"clusterid" can be used to look up all listening endpoints in a cluster by its id.
