output "id" {
  value = azurerm_private_endpoint.private_endpoint.id
}

output "name" {
  value = azurerm_private_endpoint.private_endpoint.name
}

output "ipAddress" {
  value = module.network_interface.ipAddress
}

output "ipAddress2" {
  value = module.network_interface.ipAddress2
}