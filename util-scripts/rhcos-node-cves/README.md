# Desription

This script exports all Red Hat CoreOs (RHCOS) Node CVES from an Openshift cluster with Red Hat Advanced Cluster Security installed. 

## Required Environment Vars

ROX_ENDPOINT - Host for StackRox central (central.example.com)

ROX_API_TOKEN - Token data from StackRox API token [How to generate an API Token](https://docs.openshift.com/acs/4.4/configuration/configure-api-token.html)

## Usage 

Run the script ./node-cve-report.sh to generate a results.json file with all CVE information

Optional - Save to csv (i.e. ./node-cve-report.sh > report.csv)

Important: Red Hat ACS only support Node CVE scanning for RHCOS. It is not designed for non-openshift environments running Kubernetes. See [Documentation](https://docs.openshift.com/acs/4.4/operating/manage-vulnerabilities/scan-rhcos-node-host.html) for more details.
