This script exports component details to CSV, including: cluster, namespace, deployment, image, component and component version. 

Required Environment Vars:

ROX_ENDPOINT - Host for StackRox central (central.example.com)
ROX_API_TOKEN - Token data from StackRox API token
Required Argument:

$1 = path/to/output_file.csv
Usage "component_details_csv.sh <output filename>"
