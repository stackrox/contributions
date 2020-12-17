# CircleCI Orb Sample 
 

 This sample uses an inline orb that exposes two jobs 
 
 ```
 job: rox-image-scan
 description: does a `roxctl image scan` followed by a `roxctl image check`
 parameters:
  rox_api_token:
    description: API key with CI permissions
    type: string
  rox_central_endpoint:
    description: URL of Central (central.contoso.com:443 for example)
    type: string
  rox_deployment:
    description: Path/name of yaml to check
    type: string
```
```
 job: rox-deployment-check
 description: does a `roxctl deployment check`
 parameters:
  rox_api_token:
    description: API key with CI permissions
    type: string
  rox_central_endpoint:
    description: URL of Central (central.contoso.com:443 for example)
    type: string
  rox_image_scan:
    description: Name of image to scan (neilcar/testimage:5 or registry.contoso.com/db_broker:latest for example)
    type: string
```    
  
 OWNER:  neilcar
 
 LATEST TESTED: 3.0.53.0
