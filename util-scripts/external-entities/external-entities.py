#!/usr/bin/env python3

import requests
import argparse
import os
import sys
import json

import tabulate


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

    def get_all_external_entities(self, learned=True, cidr=None):
        query = f"Learned External Source:{str(learned).lower()}"
        if cidr:
            query = f"{query}+External Source Address:{cidr}"
        return self._get(f'v1/networkgraph/cluster/{self.cluster_id()}/externalentities', params={
            "query": query
        })

    def get_external_flows_by_deployment(self, deployment_id, ingress_only=False, egress_only=False):
        return self._get(f'v1/networkgraph/cluster/{self.cluster_id()}/externalentities/flows/{deployment_id}', params={
            "ingress_only": ingress_only,
            "egress_only": egress_only,
        })

    def get_deployment_id(self, deployment_name):
        response = self._get('v1/deployments')

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

        response = requests.get(self._endpoint_path(path), params=params, headers=headers, verify=False).json()
        self._handle_error_response(response)
        return response

    def _endpoint_path(self, path):
        return f'https://{self._auth.endpoint}/{path}'

    def _handle_error_response(self, response):
        if 'error' not in response:
            return
        err(f'Error: {response['error']}')


def flows_table_output(flows, deployment_name, deployment_id):
    print(f'External flows for {deployment_name} ({deployment_id})')
    table = []
    for flow in flows.get('flows', []):
        props = flow['props']
        src, dest = props['srcEntity'], props['dstEntity']

        row = [deployment_name]
        if src['type'] == 'DEPLOYMENT':
            row.extend([dest['externalSource']['name'], dest['externalSource']['cidr'], 'EGRESS'])
        else:
            row.extend([src['externalSource']['name'], src['externalSource']['cidr'], 'INGRESS'])

        row.extend([props['dstPort'], props['l4protocol']])
        table.append(row)

    print(tabulate.tabulate(table, headers=['Deployment', 'Name', 'CIDR', 'Direction', 'Port', 'Proto']))


def endpoints_table_output(endpoints, cluster):
    print(f'External entities in cluster {cluster}')
    table = []
    for entity in endpoints.get('entities', []):
        ip = entity['info']['externalSource']['name']
        cidr = entity['info']['externalSource']['cidr']

        table.append([ip, cidr])

    print(tabulate.tabulate(table, headers=['IP', 'CIDR']))


def entities(args, auth):
    client = Client(args.cluster, auth)
    endpoints = client.get_all_external_entities(learned=not args.all, cidr=args.cidr)
    if args.json:
        json.dump(endpoints, fp=sys.stdout, indent=4)
    else:
        endpoints_table_output(endpoints, args.cluster)



def deployment(args, auth):
    client = Client(args.cluster, auth)
    deployment_id = client.get_deployment_id(args.deployment)
    flows = client.get_external_flows_by_deployment(deployment_id)
    if args.json:
        json.dump(flows, fp=sys.stdout, indent=4)
    else:
        flows_table_output(flows, args.deployment, deployment_id)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rox-endpoint", default=os.environ.get(ROX_ENDPOINT_ENV_KEY))
    parser.add_argument("--rox-api-key", default=os.environ.get(ROX_API_TOKEN_ENV_KEY))
    parser.add_argument("--json", "-j", action='store_true')

    subparsers = parser.add_subparsers(dest='subcommand')

    ent = subparsers.add_parser('entities')

    ent.add_argument('cluster')
    ent.add_argument('--all', '-a', action='store_true', help='Get all entities (not just learned entities)')
    ent.add_argument("--cidr", "-c", help='Filter by CIDR block')

    deploy = subparsers.add_parser('deployment')

    deploy.add_argument("cluster")
    deploy.add_argument("deployment")

    args = parser.parse_args()
    if not args.rox_endpoint:
        err("ROX_ENDPOINT must be set")
    if not args.rox_api_key:
        err("ROX_API_KEY must be set")

    auth = Auth(args.rox_endpoint, args.rox_api_key)

    if args.subcommand == 'entities':
        entities(args, auth)
    elif args.subcommand == 'deployment':
        deployment(args, auth)


if __name__ == '__main__':
    main()
