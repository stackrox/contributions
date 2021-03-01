This script exports all CVE data in a Policy violation such as Fixable CVSS >=7, including images, component version, fixed-in version etc.

Required Environment Vars:

ROX_ENDPOINT - Host for StackRox central (central.example.com)
ROX_API_TOKEN - Token data from StackRox API token
Required Argument:

$1 = path/to/output_file.csv
Usage "create-csv.sh <output filename>"
