Parses results from "roxctl image scan" to find the lowest-numbered ("base") image and determine its age

Output provides age of base image, in days

Usage:

`roxctl image scan -e $CENTRAL:443 --image quay.io/example:1.0 | ./base.py
`

Notes:
- Also works with the JSON returned from GET /v1/images/{id} in ACS API.
