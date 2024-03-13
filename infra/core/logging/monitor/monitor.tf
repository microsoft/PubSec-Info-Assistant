resource "azurerm_application_insights_workbook" "example" {
  name                = "85b3e8bb-fc93-40be-83f2-98f6bec18ba0"
  resource_group_name = var.resourceGroupName
  location            = var.location
  display_name        = var.logWorkbookName
  data_json = jsonencode({
    "version" = "Notebook/1.0",
    "items" = [
    {
      "type" = 1
      "content" = {
        "json" = "\r\n\r\nApplication Logs (Last 6 Hours)"
      }
      "name" = "text - 3"
    },
    {
      "type" = 3
      "content" = {
        "version" = "KqlItem/1.0"
        "query" = "AppServiceConsoleLogs | project TimeGenerated, ResultDescription, _ResourceId | where TimeGenerated > ago(6h) | order by TimeGenerated desc"
        "size" = 0
        "timeContext" = {
          "durationMs" = 86400000
        }
        "queryType" = 0
        "resourceType" = "microsoft.operationalinsights/workspaces"
        "crossComponentResources" = [
          var.componentResource
        ]
      }
      "name" = "App Logs"
    },
    {
      "type" = 1
      "content" = {
        "json" = "Function Logs (Last 6 Hours)"
      }
      "name" = "text - 4"
    },
    {
      "type" = 3
      "content" = {
        "version" = "KqlItem/1.0"
        "query" = "AppTraces | project TimeGenerated, Message, Properties | where TimeGenerated > ago(6h) | order by TimeGenerated desc"
        "size" = 0
        "timeContext" = {
          "durationMs" = 86400000
        }
        "queryType" = 0
        "resourceType" = "microsoft.operationalinsights/workspaces"
        "crossComponentResources" = [
          var.componentResource
        ]
      }
      "name" = "query - 1"
    },
    {
      "type" = 1
      "content" = {
        "json" = "App Service Deployment Logs (Last 6 Hours)"
      }
      "name" = "text - 5"
    },
    {
      "type" = 3
      "content" = {
        "version" = "KqlItem/1.0"
        "query" = "AppServicePlatformLogs | project TimeGenerated, Level, Message, _ResourceId | where TimeGenerated > ago(6h) | order by TimeGenerated desc"
        "size" = 0
        "timeContext" = {
          "durationMs" = 86400000
        }
        "queryType" = 0
        "resourceType" = "microsoft.operationalinsights/workspaces"
        "crossComponentResources" = [
          var.componentResource
        ]
      }
      "name" = "query - 2"
    }
    ],
    "isLocked" = false,
    "fallbackResourceIds" = [
      "Azure Monitor"
    ]
  })

  tags = {
    ENV = "Test"
  }
}