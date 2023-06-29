Parses results from ACS API /v1/deployments to list all running deployments, and then uses deployment details to enumerate active images.

Output lists each Deployment, and its images. "active" images are those use by any running Deployments.

Requires two environment variables:
* CENTRAL is the hostname or IP of ACS Central
* ROX_API_TOKEN is the value of an ACS API Token with minimum read access to Deployments

Optional argument as environment variable:
* NAMESPACE limits the results to a particular namespace 
