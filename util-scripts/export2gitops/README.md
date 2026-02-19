## export2gitops

A python script that takes exported StackRox policies and converts them to StackRox SecurityPolicy objects, that can be managed with GitOps. 

### Usage
python export2gitops.py -i sample-policy.json -o netcat-in-image.yaml