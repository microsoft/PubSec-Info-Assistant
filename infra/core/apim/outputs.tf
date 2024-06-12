
output "api_management_service_name" {
  value = azurerm_api_management.apim.name
}

output "identityPrincipalId" {
  value = azurerm_api_management.apim.identity.0.principal_id
}

output "apim_uri" {
  value = azurerm_api_management.apim.gateway_url
}

output "apim_subscription_key" {
 value = replace(data.local_file.subscription_key.content,"\r\n","")
}
