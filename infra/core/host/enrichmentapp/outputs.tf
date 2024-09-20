output "name" {
  value = azurerm_linux_web_app.enrichmentapp.name
}

output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_linux_web_app.enrichmentapp.identity.0.principal_id : ""
}

output "uri" {
  value = "https://${azurerm_linux_web_app.enrichmentapp.default_hostname}"
}