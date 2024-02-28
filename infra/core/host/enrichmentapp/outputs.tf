output "name" {
  value = azurerm_linux_web_app.app_service.name
}

output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_linux_web_app.app_service.identity.0.principal_id : ""
}

output "uri" {
  value = "https://${azurerm_linux_web_app.app_service.default_hostname}"
}