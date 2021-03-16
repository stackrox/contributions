# Tekton / OpenShift Pipelines Sample

## Overview

This sample includes ClusterTasks for:

|ClusterTask|Description|
|---|---|
|`rox-image-scan`|Scan an image and return results formatted as json, csv, or human-readable|
|`rox-image-check`|Check an image against build-time policies and return success/failure|
|`rox-deployment-check`|Check a deployment yaml against deploy-time policies and return success/failure}|

It also includes samples for creating secrets for the StackRox Central endpoint & API token as well as pipelines that utilize the image scanning & checking ClusterTasks.

## Installation & Testing

Use `kubectl apply -f Tasks/` or `oc apply -f Tasks/` to create the ClusterTasks for use in the cluster.

To use the samples, edit `rox-secrets.yml` to include the correct values, create a `pipeline-demo` namespace (or change the namespace in the deployment files in `Sample/`),  and run `kubectl apply -f Sample/` / `oc apply -f Sample/`.  To run the pipeline, trigger it from the Web UI or use `tkn pipeline start rox-pipeline -n pipeline-demo -p image=vulnerables/phpldapadmin-remote-dump` (passing in the image to be scanned in the `image` parameter).