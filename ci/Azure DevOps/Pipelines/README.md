# Azure DevOps Pipeline Sample 
 
 This sample is a fragment of an azure-pipelines.yml file that downloads `roxctl` and uses it to scan an image, check it against configured system policies, and generate a CSV with all packages & vulnerabilities broken down by the layer in which they were introduced.  It saves all this output as artifacts of the build.

 In order to use this sample, you should set two variables in your Azure DevOps project:

 * roxcentralendpoint -- this is the exposed address & port for your StackRox Central deployment in the form `stackrox.contoso.com:443`.
 * roxapitoken -- this is an API token with at least CI privileges.

 Change `vulnerables/cve-2017-7494` to match the image you want to scan as part of the build.
  
 OWNER:  neilcar
 
 LATEST TESTED: 3.0.53.0
