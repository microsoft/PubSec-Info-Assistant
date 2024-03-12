terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
    }
  }
}


locals {
  logic_app_filepath = "logic_apps/logicapp_SharePointFileIngestion_template.json"
}

resource "azurerm_resource_group_template_deployment" "sharepoint_logicapp" {
  name                = "sharepoint-logicapp-deployment"
  resource_group_name = var.resource_group_name
  depends_on = [ azapi_resource.blob_connector, azapi_resource.sharepointonline_connector]
  parameters_content = jsonencode({
    "workflow_name"        = { value = "infoasst-sharepointonline-${var.random_string}" },
    "subscription_id"      = { value = var.subscription_id },
    "location"             = { value = var.location },
    "resource_group_name"  = { value = var.resource_group_name }
  })
  # Assuming you have an ARM template named logic_app_template.json in the same directory as your main.tf file
  template_content    = file(local.logic_app_filepath)

  deployment_mode     = "Incremental"
}

resource "azapi_resource" "blob_connector" {
  type = "Microsoft.Web/connections@2016-06-01" # Use the appropriate API version
  name = "azureblob"
  location = var.location
  parent_id = var.resource_group_id

  body = jsonencode({
    properties = {
      displayName = "azureblob"
      api = {
        id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azureblob" # Adjust based on the service
      }
      parameterValues = {
        accountName = var.storage_account_name
        accessKey = var.storage_access_key
      }
    }
  })
}

resource "azapi_resource" "sharepointonline_connector" {
  type = "Microsoft.Web/connections@2016-06-01" # Use the appropriate API version
  name = "sharepointonline"
  location = var.location
  parent_id = var.resource_group_id

  body = jsonencode({
    properties = {
      displayName = "sharepointonline"
      api = {
        id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/sharepointonline" # Adjust based on the service
      }
    }
  })
}