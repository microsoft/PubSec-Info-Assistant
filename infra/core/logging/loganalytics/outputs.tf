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
  value = var.is_secure_mode ? azurerm_private_endpoint.ampls[0].id : null
}

output "privateEndpointName" {
  value = var.is_secure_mode ? azurerm_private_endpoint.ampls[0].name : null
}

output "privateEndpointIpAddress" {
  value = var.is_secure_mode ? azurerm_private_endpoint.ampls[0].private_service_connection[0].private_ip_address : null
}