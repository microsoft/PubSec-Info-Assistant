output "name" {
  value = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  value = azurerm_storage_account.storage.primary_queue_endpoint
}

output "primary_table_endpoint" {
  value = azurerm_storage_account.storage.primary_table_endpoint
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "blobPrivateEndpointId" {
  value = azurerm_private_endpoint.blobPrivateEndpoint.id
}

output "queuePrivateEndpointId" {
  value = azurerm_private_endpoint.queuePrivateEndpoint.id
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}
