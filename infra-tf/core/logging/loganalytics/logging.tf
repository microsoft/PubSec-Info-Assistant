
resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = var.logAnalyticsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.skuName
  tags                = var.tags
}

resource "azurerm_application_insights" "applicationInsights" {
  name                = var.applicationInsightsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  application_type    = "web"
  tags                = var.tags
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
