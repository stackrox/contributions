import json
import requests
import os
import pandas as pd
import urllib3

# check that required env variables are present
if "ROX_ENDPOINT" not in os.environ or "ROX_API_TOKEN" not in os.environ:
    print("ROX_ENDPOINT and ROX_API_TOKEN must be set")
    quit()

# disabling TLS certificate check
# for self-signed installs
urllib3.disable_warnings()

# properly formats ROX_API_TOKEN 
# for requests
class BearerAuth(requests.auth.AuthBase):
    def __init__(self, token):
        self.token = token
    def __call__(self, r):
        r.headers["authorization"] = "Bearer " + self.token
        return r

rox_endpoint = os.getenv('ROX_ENDPOINT')
rox_api_token = os.getenv('ROX_API_TOKEN')

results = {}

# Start by getting all deployments impacted by CVE-2021-44228
try:
    affected_deployments = requests.get('https://' + rox_endpoint + '/v1/deploymentswithprocessinfo?query=CVE%3ACVE-2021-44228', auth=BearerAuth(rox_api_token), verify=False).json()
except:
    print("Unable to get deployments affected by CVE-2021-44228.  Exiting")
    quit()

# Get each individual deployment
for affected_deployment in affected_deployments['deployments']:
    try:
        deployment_details = requests.get('https://' + rox_endpoint + '/v1/deploymentswithrisk/' + affected_deployment['deployment']['id'], auth=BearerAuth(rox_api_token), verify=False).json()['deployment']
    except:
        print('Unable to get details for deployment {0}/{1}/{2}'.format(deployment_details['clusterName'], deployment_details['namespace'], deployment_details['name']))
        break
    # And loop through all the container specs in the deployment
    # This allows us to return accurate results if only one container spec is affected/unaffected
    for containerspec in deployment_details['containers']:
        try:
            vulns = requests.get('https://' + rox_endpoint + '/v1/images/' + containerspec['image']['id'], auth=BearerAuth(rox_api_token), verify=False).json()['scan']['components']
        except:
            print('Unable to get vulnerabilities for container spec {3} in deployment {0}/{1}/{2}'.format(deployment_details['clusterName'], deployment_details['namespace'], deployment_details['name'], containerspec["name"]))
            break
        vuln_dataframe = pd.DataFrame(vulns)
        log4j_dataframe = vuln_dataframe[(vuln_dataframe["name"]=="log4j")]
        if log4j_dataframe.count(axis=0)["name"] > 0:
            mitigation_present = 'false'
            for container in deployment_details['containers']:
                # Check each of the two mitigation strategies
                for envvar in container['config']['env']:
                    if envvar['key'] == "LOG4J_FORMAT_MSG_NO_LOOKUPS" and envvar['value'] == "true":
                        mitigation_present = 'true'
                    elif envvar['key'] == "JAVA_TOOL_OPTIONS" and "-Dlog4j2.formatMsgNoLookups=true" in envvar['value']:
                        mitigation_present = 'true'
            # Create a deployment dict and add it to our set of results
            deployment = { 'cluster': deployment_details['clusterName'], 'namespace': deployment_details['namespace'], 'name': deployment_details['name'], 'container': containerspec["name"], 'image': containerspec['image']['name']['fullName'], 'mitigation': mitigation_present }
            results[containerspec['id']] = deployment

# Create a DataFrame and return it as CSV
results_table = pd.DataFrame.from_dict(data=results, orient='index')
print(results_table.to_csv(index=False))

