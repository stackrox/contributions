# ubi-versions.sh
## Description
This script exports deployments that are using older Red Hat Universal Base Image (UBI) versions into a CSV file. 

Exported values for deployments include:
- Cluster name
- Namespace
- Deployment name
- Image
- Universal Base Image (UBI) version

## Required environment vars
ROX_ENDPOINT - Host for StackRox central (central.example.com)

ROX_API_TOKEN - Token data from StackRox API token [How to generate an API Token](https://docs.openshift.com/acs/4.6/configuration/configure-api-token.html)

## Required policies
This policy relies on the 'UBI version compliance' policy having been imported to the cluster (also available in this repository)

## Usage
Run the script ./ubi-versions results.csv to generate a file with all deployment information.
