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

output "privateEndpointId" {
  value = azurerm_private_endpoint.ampls.id
}

output "privateEndpointName" {
  value = azurerm_private_endpoint.ampls.name
}

output "privateEndpointIpAddress" {
  value = azurerm_private_endpoint.ampls.private_service_connection[0].private_ip_address
}