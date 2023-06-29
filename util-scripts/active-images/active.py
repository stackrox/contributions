#!/usr/bin/env python3

import os
import json
import requests
import urllib3


# disable TLS certificate check warnings
urllib3.disable_warnings()

# properly formats ROX_API_TOKEN
# for requests
class BearerAuth(requests.auth.AuthBase):
    def __init__(self, token):
        self.token = token
    def __call__(self, r):
        r.headers["Authorization"] = "Bearer " + self.token
        return r

rox_central = os.getenv('CENTRAL')
rox_api_token = os.getenv('ROX_API_TOKEN')
rox_namespace = os.getenv('NAMESPACE')

if not rox_central:
    print("No endpoint defined in CENTRAL")
    quit()
if not rox_api_token:
    print("No API token found")
    quit()

# get the list of deployments
request_url="https://"+rox_central+"/v1/deployments"
if rox_namespace:
    request_url+="?query=Namespace:"+rox_namespace
try:
    deployments = requests.get (request_url, auth=BearerAuth(rox_api_token), verify=False).json()
except:
    print("Unable to get deployments. Exiting")
    quit()

for deployment in deployments["deployments"]:
    try:
        print ("found deployment with name " + deployment ["name"] + " and id " + deployment["id"])
        deployment_details = requests.get ('https://' + rox_central + '/v1/deployments/' + deployment["id"], auth=BearerAuth(rox_api_token), verify=False).json()
        for container in deployment_details["containers"]:
               try:
                   print ("---> image", container["image"]["name"]["fullName"])
               except KeyError:
                   pass
    except KeyError:
        pass
