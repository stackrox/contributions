# GitLab Sample 
 

 This sample is a fragment of a .gitlab-ci.yml file that downloads `roxctl` and uses it to scan an image & check it against configured system policies.

 In order to use this sample, you should set two environment variables in your GitLab project:

 * ROX_CENTRAL_ENDPOINT -- this is the exposed address & port for your StackRox Central deployment in the form `stackrox.contoso.com:443`.
 * ROX_API_TOKEN -- this is an API token with at least CI privileges.

 Change `my.registry/repo/image:latest` to match the image you want to scan as part of the build.
  
 OWNER:  neilcar
 
 LATEST TESTED: 3.0.51.0