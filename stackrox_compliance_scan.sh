#!/bin/bash
# clemenko@stackrox.com

standardId="NIST_800_190"
#supported standards CIS_Kubernetes_v1_5 HIPAA_164 NIST_800_190 NIST_SP_800_53_Rev_4 PCI_DSS_3_2 CIS_Docker_v1_2_0
###### no more edits

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

function setup () {  # setup role and token
    
    echo -e "\n Creating the API token. Admin password required. " 
    #read the admin password
    echo -n " - StackRox Admin Password for $serverUrl: "; read -s password; echo

    # check to see if the role is there. 
    if [ $(curl -sk -u admin:$password https://$serverUrl/v1/roles | jq '.roles[] | select(.name=="Compliance")' | wc -l) = 0 ]; then
        # create the role
        curl -sk -u admin:$password -X POST 'https://'$serverUrl'/v1/roles/Compliance' \
        -H 'accept: application/json, text/plain, */*' \
        -d '{"name":"Compliance","globalAccess":"NO_ACCESS","resourceToAccess":{"Cluster": "READ_ACCESS","Compliance":"READ_WRITE_ACCESS","ComplianceRunSchedule":"READ_WRITE_ACCESS","ComplianceRuns":"READ_WRITE_ACCESS"}}'
    fi

    # create token with new role
    curl -sk -X POST -u admin:$password https://$serverUrl/v1/apitokens/generate -d '{"name":"compliance","role":null,"roles":["Compliance"]}'| jq -r .token > stackrox_api.token

    echo -e "\n----------------------------------------------------------------------------------"
}

echo -e "\n StackRox Complaince Automation Script"
echo " - Inputs: ./stackrox_compliance_scan.sh <SERVER NAME>"
echo " - Outputs: <SERVERNAME>_<CLUSTERNAME>_<STANDARD>_Results_$(date +"%m-%d-%y").json"
echo -e "----------------------------------------------------------------------------------\n"

serverUrl=$1
if [ -z $serverUrl ]; then echo "$RED [warn]$NORMAL Please add the server name to the command."; echo ""; exit; fi

# if stackrox_api.token exists
if [ ! -f stackrox_api.token ]; then setup; fi

# get api
export token=$(cat stackrox_api.token)

echo -n "Running $standardId scan on $serverUrl "

#get clusterId
clusterId=$(curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/clusters | jq -r .clusters[0].id)

clusterName=$(curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/clusters/$clusterId | jq -r .cluster.name)

runId=$(curl -sk -X POST -H "Authorization: Bearer $token" https://$serverUrl/v1/compliancemanagement/runs -d '{"selection": { "clusterId": "'"$clusterId"'", "standardId": "'"$standardId"'" }}' | jq -r .startedRuns[0].id)

until [ "$(curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/complianceManagement/runs | jq -r '.complianceRuns[]|select(.id=="'"$runId"'") | .state' )" == "FINISHED" ]; do echo -n "."; sleep 1; done

curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/compliance/runresults?clusterId="$clusterId"'&standardId='$standardId'&runId='$runId'' | jq . > "$serverUrl"_"$clusterName"_"$standardId"_Results_$(date +"%m-%d-%y").json

echo -e "$GREEN" "[ok]" "$NORMAL\n"
