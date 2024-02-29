output "id" {
  value = azurerm_private_endpoint.private_endpoint.id
}

output "name" {
  value = azurerm_private_endpoint.private_endpoint.name
}

output "ipAddress" {
  value = azurerm_private_endpoint.private_endpoint.private_service_connection.private_ip_address
}