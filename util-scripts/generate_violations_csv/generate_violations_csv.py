import os, shutil
import requests
import pandas as pd
import json
from pandas import json_normalize
from datetime import datetime
import argparse


def convert_argsparse(value):
    return value.replace('+', '%2B')

parser = argparse.ArgumentParser(description='Provide filter to ACS query')
parser.add_argument('--query_scope', type=str, help='limit query to cluster/namespace, e.g: Cluster:cluster_name, Cluster:cluster_name+Namespace:namespace_name"', required=True)
args = parser.parse_args()
query_scope = convert_argsparse(args.query_scope)


current_date = datetime.now().strftime("%Y-%m-%d")
tmp_workdir = f"reports/tmp"

violations_csv = f"{tmp_workdir}/violations_raw_{query_scope}_{current_date}.csv"
violations_images_list_tmp = f"{tmp_workdir}/violations_images_list_{query_scope}_{current_date}.txt"
violations_csv_tmp = f"{tmp_workdir}/violations_{query_scope}_{current_date}.csv"

violations_images_csv = f"reports/violations_images_{query_scope}_{current_date}.csv"

acs_api_key = os.getenv('acs_api_key')
acs_central_api = os.getenv('acs_central_api')

def verify_acs_api_key(acs_api_key):
    if acs_api_key is None:
        raise Exception("ACS API key not found.")
    if acs_central_api is None:
        raise Exception("ACS Central API endpoint not found.")

def pull_violations(acs_api_key,query_scope):
    offset = 0
    limit = 50 
    all_violations = []

    while True:
        if query_scope == 'all':
            endpoint = f"{acs_central_api}/alerts?&pagination.offset={offset}&pagination.limit={limit}&pagination.sortOption.field=Violation Time&pagination.sortOption.reversed=true"
            headers = {'Authorization': f'Bearer {acs_api_key}'}
        else:
            endpoint = f"{acs_central_api}/alerts?query={query_scope}&pagination.offset={offset}&pagination.limit={limit}&pagination.sortOption.field=Violation Time&pagination.sortOption.reversed=true"
            headers = {'Authorization': f'Bearer {acs_api_key}'}
            
        response = requests.get(endpoint, headers=headers)
        response_body = response.json()
        
        if isinstance(response_body, dict) and 'alerts' in response_body:
              results = response_body['alerts']
              print(f"INFO : pulled {len(results)} violations")
        else:
              print("ERROR: no violations found")
              results = []
        all_violations.extend(results)

        if len(results) < limit:
                break
        else:
                offset += limit
    return all_violations


def pull_violations_images(acs_api_key):
    violations_images = []
    image_names_list = []

    alert_ids = [item['id'] for item in violations_data]

    for alert_id in alert_ids:
        headers = {'Authorization': f'Bearer {acs_api_key}'}
        response = requests.get(f"{acs_central_api}/alerts/{alert_id}",headers=headers)
        if response.status_code == 200:
            result = response.json()
            violations_images.append(result)

            image_names = []
            try:
              containers = result['deployment']['containers']
              for container in containers:
                  full_name = container['image']['name']['fullName']
                  image_names.append(full_name)
            except KeyError:
                print(f"ERROR: failed to find image names for alert_id: {alert_id}")

        if image_names:
            output = ','.join(image_names) if len(image_names) > 1 else image_names[0]
            image_names_list.append(output)


    with open(violations_images_list_tmp, 'w') as output_file:
        for image_names in image_names_list:
            output_file.write(f"{image_names}\n")


def construct_violations_csv(violations_csv):
    df = pd.read_csv(violations_csv)
    columns_to_delete = [0,1,2,3,4,5,6,8,9,10,11,12,13,14,15,16,17,21,22,23]
    df.drop(df.columns[columns_to_delete], axis=1, inplace=True)
    df.to_csv(violations_csv_tmp, index=False)

    df = pd.read_csv(violations_csv_tmp)
    with open(violations_images_list_tmp, 'r') as f:
        images_list = f.read().splitlines()
    df['images'] = images_list
    df.to_csv(violations_images_csv , index=False)


##### <<< main >>> #######

verify_acs_api_key(acs_api_key)

os.makedirs(tmp_workdir, exist_ok=True)


violations_data = pull_violations(acs_api_key,query_scope)
print(f"INFO : pulled total of {len(violations_data)} violations")


if violations_data:
    df = json_normalize(violations_data)
else:
    df = pd.DataFrame()
df.to_csv(violations_csv , index=False)

print("INFO : matching image names to violations")
violation_images = pull_violations_images(acs_api_key)

print("INFO : exporting csv")
construct_violations_csv(violations_csv)


shutil.rmtree(tmp_workdir)
