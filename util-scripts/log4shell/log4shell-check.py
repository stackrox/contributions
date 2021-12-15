import json
import requests
import os
import pandas as pd
import urllib3

urllib3.disable_warnings()

class BearerAuth(requests.auth.AuthBase):
    def __init__(self, token):
        self.token = token
    def __call__(self, r):
        r.headers["authorization"] = "Bearer " + self.token
        return r

rox_endpoint = os.getenv('ROX_ENDPOINT')
rox_api_key = os.getenv('ROX_API_TOKEN')

results = {}

affected_deployments = requests.get('https://' + rox_endpoint + '/v1/deploymentswithprocessinfo?query=CVE%3ACVE-2021-44228', auth=BearerAuth(rox_api_key), verify=False).json()

for affected_deployment in affected_deployments['deployments']:
    deployment_details = requests.get('https://' + rox_endpoint + '/v1/deploymentswithrisk/' + affected_deployment['deployment']['id'], auth=BearerAuth(rox_api_key), verify=False).json()['deployment']
    mitigation_present = 'false'
    for container in deployment_details['containers']:
        for envvar in container['config']['env']:
            if envvar['key'] == "LOG4J_FORMAT_MSG_NO_LOOKUPS" and envvar['value'] == "true":
                mitigation_present = 'true'
    deployment = { 'cluster': deployment_details['clusterName'], 'name': deployment_details['name'], 'mitigation': mitigation_present }
    results[deployment_details['id']] = deployment

results_table = pd.DataFrame.from_dict(data=results, orient='index')
print(results_table.to_string(index=False))

