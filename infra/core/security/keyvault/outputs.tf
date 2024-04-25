output "keyVaultName" {
  value = azurerm_key_vault.kv.name
}

output "keyVaultId" {
  value = azurerm_key_vault.kv.id
}

output "keyVaultUri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "keyvault_subnet_id" {
  value = azurerm_subnet.kv_subnet.id 
}

output "vnet_name" {
  value = var.vnet_name
}