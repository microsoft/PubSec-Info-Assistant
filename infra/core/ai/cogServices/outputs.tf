output "cognitiveServicerAccountName" {
  value = azurerm_cognitive_account.cognitiveService.name
}

output "cognitiveServiceID" {
  value = azurerm_cognitive_account.cognitiveService.id
}

output "cognitiveServiceEndpoint" {
  value = azurerm_cognitive_account.cognitiveService.endpoint
}

output "privateEndpointName" {
  value = var.is_secure_mode ? azurerm_private_endpoint.accountPrivateEndpoint[0].name : null
}

output "privateEndpointId" {
  value = var.is_secure_mode ? azurerm_private_endpoint.accountPrivateEndpoint[0].id : null
}

output "privateEndpointIp" {
  value = var.is_secure_mode ? azurerm_private_endpoint.accountPrivateEndpoint[0].private_service_connection[0].private_ip_address : null
}
