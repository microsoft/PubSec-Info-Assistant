output "name" {
  value = azurerm_storage_account.storage.name
}

output "primary_endpoints" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "blobPrivateEndpointId" {
  value = var.is_secure_mode ? azurerm_private_endpoint.blobPrivateEndpoint[0].id : null
  
}

output "queuePrivateEndpointId" {
  value = var.is_secure_mode ? azurerm_private_endpoint.queuePrivateEndpoint[0].id : null
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}