#!/usr/bin/env python3

import sys
import json
from datetime import datetime, timedelta

gracePeriod=30
currentTime=datetime.now()

image_json = json.load(sys.stdin)

returnCode=0

for component in image_json["scan"]["components"]:
    try:
        for vuln in component["vulns"]:
            try:
                if vuln["fixedBy"]:
                    pubTimestamp = datetime.strptime(vuln["publishedOn"][0:10], "%Y-%m-%d")
                    if (currentTime - timedelta(days=gracePeriod)) > pubTimestamp:
                        print ("out of grace: ", component["name"], vuln["cve"], vuln["severity"], vuln["fixedBy"], vuln["publishedOn"])
                        returnCode=1
                    else:
                        print ("in grace: ", component["name"], vuln["cve"], vuln["severity"], vuln["fixedBy"], vuln["publishedOn"])
                    #print (vuln["cve"])
            except KeyError:
                pass
    except KeyError:
        pass

exit(returnCode)
