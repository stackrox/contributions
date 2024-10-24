resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-resources"
  location = var.region
}

resource "azurerm_monitor_data_collection_endpoint" "endpoint" {
  name                          = "${var.prefix}-data-collection-endpoint"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  public_network_access_enabled = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_log_analytics_workspace" "logworkspace" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# We are using the azapi provider to create custom tables because it is unsupported in the Azure provider.
# This resource links to the data_flow.output_stream field in the `azurerm_monitor_data_collection_rule` resource.
resource "azapi_resource" "data_collection_logs_table" {
  name      = "stackrox_alerts_CL"
  parent_id = azurerm_log_analytics_workspace.logworkspace.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = jsonencode(
    {
      "properties" : {
        "schema" : {
          "name" : "stackrox_alerts_CL",
          "columns" : [
            {
              "name" : "TimeGenerated",
              "type" : "datetime",
              "description" : "The time at which the data was generated"
            },
            {
              "name" : "msg",
              "type" : "dynamic",
              "description" : "StackRox alert message sent by a notifer"
            }
          ]
        },
        "retentionInDays" : 30,
        "totalRetentionInDays" : 30
      }
    }
  )
}

# Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "rule" {
  name                        = "${var.prefix}-data-collection-rule"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.endpoint.id
  description                 = "StackRox data collection rule to forward StackRox alerts to the Log Analytics Workspace."

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.logworkspace.id
      name                  = "destination-logs"
    }
  }

  data_flow {
    streams      = ["Custom-stackrox_alerts_CL"]
    destinations = ["destination-logs"]

    # From `data_collection_logs_table.name`. The prefix is prepended by Azure automatically.
    output_stream = "Custom-stackrox_alerts_CL"
  }

  stream_declaration {
    stream_name = "Custom-stackrox_alerts_CL"
    column {
      name = "msg"
      type = "dynamic"
    }
    column {
      name = "TimeGenerated"
      type = "datetime"
    }
  }

  depends_on = [
    azurerm_log_analytics_workspace.logworkspace,
    azapi_resource.data_collection_logs_table
  ]
}

