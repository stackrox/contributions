# Argo Workflow Example 
 
Provided is an Argo Workflow resource that will build, push, scan and check a container image. 
This workflow will also render a K8s deployment resource and check that against StackRox policies
 
### PreReqs:
* Argo
* K8s imagePullSecret named: `stackrox-io`
* K8s secret: `rox-api` with the `data` key set to the StackRox API token
* K8s secret: `regcred` with `config.json` container docker registry credentials (for pushing) 
  
### Overrides:
The workflow has the following values that can be overriden at submit time from the CLI:
* `git-repo-path`: ex "https://github.com/logankimmel/hello-go.git"
* `image-repo`: ex "docker.io/logankimmel/hello-go"

### Required Param:
* `central`: Central hostname and port, ex: "central.rox.binbytes.io:443"
  * This must be declared on the command line: 
    `argo submit argo.yml -n argo -v -p central="central.rox.binbytes.io:443"`
 
 LATEST TESTED: 3.0.50.0