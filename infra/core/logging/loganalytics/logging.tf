
resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = var.logAnalyticsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.skuName
  tags                = var.tags
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "logAnalytics" {
  name                       = var.logAnalyticsName
  target_resource_id         = azurerm_log_analytics_workspace.logAnalytics.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id

  enabled_log {
    category = "Audit"
  }
  enabled_log {
    category = "SummaryLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_application_insights" "applicationInsights" {
  name                = var.applicationInsightsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  application_type    = "web"
  tags                = var.tags
  workspace_id        = azurerm_log_analytics_workspace.logAnalytics.id
}

resource "azurerm_monitor_diagnostic_setting" "applicationInsights" {
  name                       = var.applicationInsightsName
  target_resource_id         = azurerm_application_insights.applicationInsights.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id

  enabled_log {
    category = "AppAvailabilityResults"
  }
  enabled_log {
    category = "AppBrowserTimings"
  }
  enabled_log {
    category = "AppEvents"
  }
  enabled_log {
    category = "AppMetrics"
  }
  enabled_log {
    category = "AppDependencies"
  }
  enabled_log {
    category = "AppExceptions"
  }
  enabled_log {
    category = "AppPageViews"
  }
  enabled_log {
    category = "AppPerformanceCounters"
  }
  enabled_log {
    category = "AppRequests"
  }
  enabled_log {
    category = "AppSystemEvents"
  }
  enabled_log {
    category = "AppTraces"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "applicationInsightsId" {
  value = azurerm_application_insights.applicationInsights.id
}

output "logAnalyticsId" {
  value = azurerm_log_analytics_workspace.logAnalytics.id
}

output "applicationInsightsName" {
  value = azurerm_application_insights.applicationInsights.name
}

output "logAnalyticsName" {
  value = azurerm_log_analytics_workspace.logAnalytics.name
}

output "applicationInsightsInstrumentationKey" {
  value = azurerm_application_insights.applicationInsights.instrumentation_key
}

output "applicationInsightsConnectionString" {
  value = azurerm_application_insights.applicationInsights.connection_string
}
