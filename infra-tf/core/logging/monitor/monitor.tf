# resource "azurerm_monitor_log_query" "app_logs" {
#   name                = "AppLogsQuery"
#   resource_group_name = var.resource_group_name
#   workspace_id        = var.logAnalyticsId

#   query = <<-EOT
#     AppServiceConsoleLogs
#     | project TimeGenerated, ResultDescription, _ResourceId
#     | where TimeGenerated > ago(6h)
#     | order by TimeGenerated desc
#   EOT
# }

# resource "azurerm_monitor_log_query" "function_logs" {
#   name                = "FunctionLogsQuery"
#   resource_group_name = var.resource_group_name
#   workspace_id        = var.logAnalyticsId

#   query = <<-EOT
#     AppTraces
#     | project TimeGenerated, Message, Properties
#     | where TimeGenerated > ago(6h)
#     | order by TimeGenerated desc
#   EOT
# }

# resource "azurerm_monitor_log_query" "deployment_logs" {
#   name                = "DeploymentLogsQuery"
#   resource_group_name = var.resource_group_name
#   workspace_id        = var.logAnalyticsId

#   query = <<-EOT
#     AppServicePlatformLogs
#     | project TimeGenerated, Level, Message, _ResourceId
#     | where TimeGenerated > ago(6h)
#     | order by TimeGenerated desc
#   EOT
# }

# Now, deploy the ARM template with the workbook definition
resource "azurerm_template_deployment" "workbook" {
  name                = "workbook-deployment"
  resource_group_name = var.resourceGroupName
  deployment_mode     = "Incremental" // Add this line
  template_body       = <<-EOT
    {
      "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "resources": [
        {
          "type": "Microsoft.Insights/workbooks",
          "apiVersion": "2020-11-20",
          "name": "example-workbook",
          "location": "${var.location}",
          "properties": {
            "displayName": "Example Workbook",
            "serializedData": "...base64-encoded JSON content...",
            "category": "Deployed Template",
            "resourceType": "Azure Monitor",
            "type": "workbook"
          }
        }
      ]
    }
  EOT
}