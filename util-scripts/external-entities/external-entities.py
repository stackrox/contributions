#!/usr/bin/env python3

import requests
import argparse
import os
import sys
import json


ROX_ENDPOINT_ENV_KEY = "ROX_ENDPOINT"
ROX_API_TOKEN_ENV_KEY = "ROX_API_TOKEN"


def err(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


class Auth:
    def __init__(self, endpoint, api_key):
        self.endpoint = endpoint
        self.api_key = api_key


class Client:
    def __init__(self, cluster, auth):
        self._auth = auth
        self._cluster = cluster
        self._cluster_id = None

    def get_external_endpoints(self):
        return self._get(f'v1/networkgraph/cluster/{self.cluster_id()}/externalentities', params={
            #"query": "Learned External Source:true",
        })

    def get_external_endpoints_by_deployment(self, deployment_id):
        return self._get(f'v1/networkgraph/cluster/{self.cluster_id()}/externalentities/{deployment_id}', params={
            "query": "Learned External Source:true",
        })

    def get_deployment_id(self, deployment_name):
        response = self._get('v1/deployments')

        json.dump(response, fp=sys.stdout, indent=4)

        deployments = list(filter(lambda x: x['name'] == deployment_name, response.get('deployments', [])))
        if len(deployments) != 1:
            err(f"Unable to find deployment with name: {deployment_name}")

        return deployments[0]['id']

    def get_cluster_id(self):
        response = self._get('v1/clusters', params={
            'query': f'Cluster:{self._cluster}'
        })

        clusters = response.get('clusters', [])
        if len(clusters) != 1:
            err(f"Unable to find cluster with name: {self._cluster}")

        cluster = clusters[0]
        return cluster["id"]

    def cluster_id(self):
        if self._cluster_id is None:
            self._cluster_id = self.get_cluster_id()
        return self._cluster_id

    def _get(self, path, headers=None, params=None):
        if not headers:
            headers = {}

        headers.update({
            'Authorization': f'Bearer {self._auth.api_key}',
        })

        response = requests.get(self._endpoint_path(path), params=params, headers=headers, verify=False)
        return response.json()

    def _endpoint_path(self, path):
        return f'https://{self._auth.endpoint}/{path}'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("cluster")
    parser.add_argument("--rox-endpoint", default=os.environ.get(ROX_ENDPOINT_ENV_KEY))
    parser.add_argument("--rox-api-key", default=os.environ.get(ROX_API_TOKEN_ENV_KEY))
    parser.add_argument("--deployment")

    args = parser.parse_args()
    if not args.rox_endpoint:
        err("ROX_ENDPOINT must be set")
    if not args.rox_api_key:
        err("ROX_API_KEY must be set")

    auth = Auth(args.rox_endpoint, args.rox_api_key)
    client = Client(args.cluster, auth)

    if args.deployment:
        deployment_id = client.get_deployment_id(args.deployment)
        print(deployment_id)
        json.dump(client.get_external_endpoints_by_deployment(deployment_id), fp=sys.stdout, indent=4)
    else:
        json.dump(client.get_external_endpoints(), fp=sys.stdout, indent=4)


if __name__ == '__main__':
    main()
