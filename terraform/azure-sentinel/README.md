# Azure Log Analytics - Sentinel Terraform

This terraform script will provide all resources to setup an integration with Sentinel and Log Analytics Workspace. 

This terraform script will provision following resources:

 - Resource group 
 - Log Analytics Workspace
 - Data Collection Endpoint
 - Data Collection Rule

This script can be used to provision a custom environment and is used for CI testing.

For more information visit the documentation in the [stackrox repo's Sentinel notifier](https://github.com/stackrox/stackrox/tree/master/central/notifiers/microsoftsentinel).

## Quick start

Requirements:

 - Install azcli
 - Authenticating via a [Service Principal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
 - Access to the Microsoft Azure StackRox tenant
 - Access to bitwarden

```
# Login into Azure, select the subscription. 
$ az login

$ export ARM_SUBSCRIPTION_ID="<id>"
$ export ARM_CLIENT_SECRET="<password>"
$ export ARM_TENANT_ID="<tenant_id>"
$ export ARM_CLIENT_ID="<client_d>"

$ terraform init
$ terraform fmt
$ terraform validate
$ terraform apply
```

For later reference example Data Collection Rule configuration: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/examples/azure-monitoring/data-collection-rule/main.tf

### Create a service principal

In case you need a new service principal you can run the command below. Please only use this if you are
sure you need new credentials. Make sure to save them in bitwarden.

```
# Create a service principal for authentication
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$ARM_SUBSCRIPTION_ID"

{
  "appId": "<appid>",
  "displayName": "azure-cli-2024-10-07-08-49-10",
  "password": "<password>",
  "tenant": "<tenanid>"
}
```
