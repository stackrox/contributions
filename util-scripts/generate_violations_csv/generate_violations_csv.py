import os
import shutil
import requests
import pandas as pd
from pandas import json_normalize
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

def verify_api_key(acs_api_key,acs_central_api):
    if acs_api_key is None:
        raise Exception("acs_api_key not found.")
    if acs_central_api is None:
        raise Exception("acs_central_api not found.")    

def pull_violations(acs_api_key,acs_central_api):
    offset = 0
    limit = 500 
    all_violations = []

    while True:
        endpoint = f"https://{acs_central_api}/v1/alerts?&pagination.offset={offset}&pagination.limit={limit}&pagination.sortOption.field=Violation Time&pagination.sortOption.reversed=true"
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

def pull_violations_images(acs_api_key, violations_data):
    image_names_list = []

    def fetch_image_names(alert_id):
        headers = {'Authorization': f'Bearer {acs_api_key}'}
        response = requests.get(f"https://{acs_central_api}/v1/alerts/{alert_id}", headers=headers)
        if response.status_code == 200:
            result = response.json()

            image_names = []
            try:
                containers = result['deployment']['containers']
                for container in containers:
                    full_name = container['image']['name']['fullName']
                    image_names.append(full_name)
            except KeyError:
                print(f"ERROR: failed to find image names for alert_id: {alert_id}")

            if image_names:
                return ','.join(image_names) if len(image_names) > 1 else image_names[0]
            else:
                return 'N/A'
        else:
            print(f"ERROR: failed to retrieve data for alert_id: {alert_id}")
            return 'N/A'

    with ThreadPoolExecutor(max_workers=10) as executor:
        future_to_alert = {executor.submit(fetch_image_names, item['id']): item['id'] for item in violations_data}
        for future in as_completed(future_to_alert):
            image_names_list.append(future.result())

    with open(violations_images_list_tmp, 'w') as output_file:
        for image_names in image_names_list:
            output_file.write(f"{image_names}\n")

def construct_violations_csv():
    df = pd.read_csv(violations_csv)
    columns_to_keep = [
        'policy.name', 
        'policy.severity',
        'deployment.name', 
        'deployment.clusterName', 
        'deployment.namespace'
        
    ]
    df = df[columns_to_keep]

    with open(violations_images_list_tmp, 'r') as f:
        images_list = f.read().splitlines()
    df['images'] = images_list
    df.to_csv(violations_images_csv, index=False)

##### <<< main >>> #######

current_date = datetime.now().strftime("%Y-%m-%d")

tmp_workdir = "reports/tmp"
violations_csv = f"{tmp_workdir}/violations_raw_{current_date}.csv"
violations_images_list_tmp = f"{tmp_workdir}/violations_images_list_{current_date}.txt"
violations_csv_tmp = f"{tmp_workdir}/violations_{current_date}.csv"
violations_images_csv = f"reports/violations_images_{current_date}.csv"

acs_api_key = os.getenv('acs_api_key')
acs_central_api = os.getenv('acs_central_api')

verify_api_key(acs_api_key,acs_central_api)
os.makedirs(tmp_workdir, exist_ok=True)

violations_data = pull_violations(acs_api_key,acs_central_api)
print(f"INFO : pulled total of {len(violations_data)} violations")

if violations_data:
    df = json_normalize(violations_data)
    df.to_csv(violations_csv, index=False)
    print("INFO : matching image names to violations")
    pull_violations_images(acs_api_key, violations_data)
    print("INFO : exporting to csv")
    construct_violations_csv()
    print(f"INFO : CSV file saved at {violations_images_csv}")
else:
    print("ERROR: No violations data available, skipping CSV")

shutil.rmtree(tmp_workdir)
