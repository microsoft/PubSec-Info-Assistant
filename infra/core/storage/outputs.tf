output "name" {
  value = azurerm_storage_account.storage.name
}

output "primary_endpoints" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "id" {
  value = azurerm_storage_account.storage.id
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}