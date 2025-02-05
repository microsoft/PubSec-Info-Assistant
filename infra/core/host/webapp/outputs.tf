output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_linux_web_app.app_service.identity.0.principal_id : ""
}

output "web_app_name" {
  value = azurerm_linux_web_app.app_service.name
}

output "uri" {
  value = "https://${azurerm_linux_web_app.app_service.default_hostname}"
}

output "web_serviceplan_name" {
  value = azurerm_service_plan.appServicePlan.name
}