output "cognitiveServicesAccountName" {
  value = azurerm_cognitive_account.cognitiveService.name
}

output "cognitiveServicesID" {
  value = azurerm_cognitive_account.cognitiveService.id
}

output "cognitiveServicesEndpoint" {
  value = azurerm_cognitive_account.cognitiveService.endpoint
}

output "privateEndpointName" {
  value = azurerm_private_endpoint.accountPrivateEndpoint.name
}

output "privateEndpointId" {
  value = azurerm_private_endpoint.accountPrivateEndpoint.id
}

output "privateEndpointIp" {
  value = azurerm_private_endpoint.accountPrivateEndpoint.private_service_connection[0].private_ip_address
}
