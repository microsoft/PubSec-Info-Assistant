
output "api_management_service_name" {
  value = azurerm_api_management.apim.name
}

output "identityPrincipalId" {
  value = azurerm_api_management.apim.identity.0.principal_id
}