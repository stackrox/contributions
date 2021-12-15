# log4shell mitigation checker

This Python 3 script uses the StackRox API to find all deployments affected by CVE-2021-44228 and check whether environment variable based mitigations have been applied

**Required Environment Vars:**
* `ROX_ENDPOINT` - Host for StackRox central (central.example.com)
* `ROX_API_TOKEN` - Token data from [StackRox API token](https://docs.openshift.com/acs/3.67/integration/integrate-with-ci-systems.html#cli-authentication_integrate-with-ci-systems)


**Usage**
`python3 log4shell-check.py >  /tmp/output.csv`