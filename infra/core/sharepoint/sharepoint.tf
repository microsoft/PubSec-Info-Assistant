locals {
  logic_app_filepath = "logic_apps/logicapp_SharePointFileIngestion_template.json"
}

resource "azurerm_resource_group_template_deployment" "sharepoint_logicapp" {
  name                = "sharepoint-logicapp-deployment"
  resource_group_name = var.resource_group_name
  parameters_content = jsonencode({
    "workflow_name"        = { value = "infoasst-sharepointonline-${var.random_string}" },
    "location"             = { value = var.location },
    "storage_account_name" = { value = var.storage_account_name },
    "storage_account_key"   = { value = var.storage_access_key }
  })
  # Assuming you have an ARM template named logic_app_template.json in the same directory as your main.tf file
  template_content    = file(local.logic_app_filepath)

  deployment_mode     = "Incremental"
}