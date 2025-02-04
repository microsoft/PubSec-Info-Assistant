output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "admin_password" {
  value = azurerm_container_registry.acr.admin_password
}

output "name" {
  value = azurerm_container_registry.acr.name
}

output "privateEndpointId" {
  value = var.is_secure_mode ? azurerm_private_endpoint.ContainerRegistryPrivateEndpoint[0].id : null
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}