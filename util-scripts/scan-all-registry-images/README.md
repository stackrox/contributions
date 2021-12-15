# Scan All Images in an ECR Registry using roxctl

This script uses roxctl to scan all images in all ecr image registries within an AWS region.Note: The images scanned in these registries will appear as 'inactive' in the GUI for ACS unless currently running within a deployment in the runtime environment. Scan results for vulnerabilities can still be analyzed from the UI. 

**Prereqs**
* The aws cli must be installed and configured for use
* A secret containing the value of the API token for Central must be created in AWS secrets manager and referenced in the environment variable (see below) 

**Required Environment Vars**
* `ROX_CENTRAL_ADDRESS` - Host for StackRox central (central.example.com)
* `ROX_SECRET_TOKEN_LOCATION` - Location of secret value in AWS Secrets Manager containing the ROX_API_TOKEN string (see https://docs.openshift.com/acs/3.67/cli/getting-started-cli.html#cli-authentication_cli-getting-started for more detail on generating a token) 
*  `AWS_REGION` - AWS region containing the ecr repositories you would like to scan

**Usage**
`./ecr-scan-roxctl.sh`

