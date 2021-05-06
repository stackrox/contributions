#!/bin/bash

#here is how to use the API to push a logon banner as well as header and footers for classification. 
# ac - 8/18/2020

central_server=stackrox.dockr.life:443

#########

function get_password (){
#read the admin password
echo -n " - StackRox Admin Password for $serverUrl: "; read -s password; echo
}

#gov logon message
export gov_message=$(cat <<EOF
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.\n\nBy using this IS (which includes any device attached to this IS), you consent to the following conditions:\n\n-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.\n\n-At any time, the USG may inspect and seize data stored on this IS.\n\n-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.\n\n-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.\n\n-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
EOF
)

case $1 in
U )
#unclass
get_password
curl -sk -X PUT -u admin:$password https://$central_server/v1/config -d '{"config":{"publicConfig":{"loginNotice":{"enabled":true,"text":"'"$gov_message"'"},"header":{"enabled":true,"text":"UNCLASSIFIED","size":"MEDIUM","color":"#ffffff","backgroundColor":"#5cb85c"},"footer":{"enabled":true,"text":"UNCLASSIFIED","size":"MEDIUM","color":"#ffffff","backgroundColor":"#5cb85c"}},"privateConfig":{"alertConfig":{"resolvedDeployRetentionDurationDays":7,"deletedRuntimeRetentionDurationDays":7,"allRuntimeRetentionDurationDays":30},"imageRetentionDurationDays":7}}}' > /dev/null 2>&1
;;

S )
#secret
get_password
curl -sk -X PUT -u admin:$password https://$central_server/v1/config -d '{"config":{"publicConfig":{"loginNotice":{"enabled":true,"text":"'"$gov_message"'"},"header":{"enabled":true,"text":"SECRET","size":"MEDIUM","color":"#ffffff","backgroundColor":"#d9534f"},"footer":{"enabled":true,"text":"SECRET","size":"MEDIUM","color":"#ffffff","backgroundColor":"#d9534f"}},"privateConfig":{"alertConfig":{"resolvedDeployRetentionDurationDays":7,"deletedRuntimeRetentionDurationDays":7,"allRuntimeRetentionDurationDays":30},"imageRetentionDurationDays":7}}}' > /dev/null 2>&1
;;

TS )
#top secret
get_password
curl -sk -X PUT -u admin:$password https://$central_server/v1/config -d '{"config":{"publicConfig":{"loginNotice":{"enabled":true,"text":"'"$gov_message"'"},"header":{"enabled":true,"text":"TOP SECRET","size":"MEDIUM","color":"#ffffff","backgroundColor":"#f0ad4e"},"footer":{"enabled":true,"text":"TOP SECRET","size":"MEDIUM","color":"#ffffff","backgroundColor":"#f0ad4e"}},"privateConfig":{"alertConfig":{"resolvedDeployRetentionDurationDays":7,"deletedRuntimeRetentionDurationDays":7,"allRuntimeRetentionDurationDays":30},"imageRetentionDurationDays":7}}}' > /dev/null 2>&1
;;

clear )
#clear
get_password
curl -sk -X PUT -u admin:$password https://$central_server/v1/config -d '{"config":{"publicConfig":{"loginNotice":{"enabled":false,"text":"'"$gov_message"'"},"header":{"enabled":false,"text":"","size":"MEDIUM","color":"#ffffff","backgroundColor":"#f0ad4e"},"footer":{"enabled":false,"text":"","size":"MEDIUM","color":"#ffffff","backgroundColor":"#f0ad4e"}},"privateConfig":{"alertConfig":{"resolvedDeployRetentionDurationDays":7,"deletedRuntimeRetentionDurationDays":7,"allRuntimeRetentionDurationDays":30},"imageRetentionDurationDays":7}}}' > /dev/null 2>&1
;;

        *) echo "Usage: $0 {clear | TS | S | U}"; exit 1

esac
