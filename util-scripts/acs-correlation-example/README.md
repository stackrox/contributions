# Prototype application to parse multiple ACS endpoints collect metadata via the API, correlate data and parse out JSON files.
- Will parse out a hierarchical Cluster->Namespace->Deployment->Alerts Relationship
- Can be extended to parse out other relationships

# Configuration
- Configuration settings are mostly obtained from enviromnent variables. Configuration settings are provided and explained in [config file](./config.py)

- The list of endpoints for the app to poll can be set via ENDPOINT_LIST_JSON_PATH environment variable. The environment variable should point to a json file with API details. A sample file is provided in [endpoint_list.json](./endpoint_list.json).While environment details are provided via the previously mentioned variable the token used for connection is obtained via enviroment variable. And the token environment variable must be set in the endpoint json file and defined by field "endpoint_token_env_variable_name".

- Generate's sample output files in output folder, but can be customized for other use cases.
  - cluster_namespace_deployment_alert.json: JSON file with hierarchical Cluster->Namespace->Deployment->Alerts relationship.
  - endpoint_policy_alert_count.json: JSON file with ACS Endpoint -> Policy -> AlertCount Relationship

# Run with Podman 
  - Build Image 
      ```bash
      podman build -t quick_acs_app .
      ```

  - Copy and update endpoint list file and token
      ```bash
      export CENTRAL_API_URL="https://console-openshift-console.apps.cluster1.sandbox568.opentlc.com"
      export MAIN_ACS_TOKEN=""
      export ENDPOINT_DIR=$(mktemp -d -t ACS_Endpoint_List_XXXX )
      export OUTPUT_FILE_DIR=$(mktemp -d -t ACS_Output_DIR_XXXX )
      cat ./endpoint_list.json | envsubst > ${ENDPOINT_DIR}/endpoint_list.json
      ```

  - Run Container
    ```bash
    podman run --name acs_correlator \
    --replace \
    --userns=keep-id \
    --env MAIN_ACS_TOKEN=${MAIN_ACS_TOKEN} \
    --env ENDPOINT_LIST_JSON_PATH=/endpoint/endpoint_list.json \
    --env OUTPUT_FOLDER=/output \
    -v ${OUTPUT_FILE_DIR}:/output:z \
    -v ${ENDPOINT_DIR}:/endpoint:z \
    localhost/quick_acs_app
    ```
 - If All goes well sample output should get written out to ${OUTPUT_FILE_DIR}

 - TODO:
   - Example uses the [Pydantic Library to create models to export out objects relationships](https://docs.pydantic.dev/1.10/usage/exporting_models/#advanced-include-and-exclude).
   - The sample relationships used for output can be seen in the [app.py](util-scripts/acs-correlation-example/app.py) on line 866
   - Will eventually extend this example to get custom relationships and export out a file.
