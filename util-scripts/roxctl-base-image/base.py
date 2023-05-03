#!/usr/bin/env python3

import sys
import json
from datetime import datetime, timedelta

currentTime=datetime.now()

image_json = json.load(sys.stdin)

returnCode=0

try:
    if created := image_json["metadata"]["v1"]["layers"][0]["created"]:
        print ("created: ", created)
        createdDate = datetime.strptime(created[0:10], "%Y-%m-%d")
        timeDiff = currentTime - createdDate
        print ("base image is", timeDiff.days, "days old")
except KeyError:
    print ("base image layer not found")
    pass

exit(returnCode)
