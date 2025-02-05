output "keyVaultName" {
  value = azurerm_key_vault.kv.name
}

output "keyVaultId" {
  value = azurerm_key_vault.kv.id
}

output "keyVaultUri" {
  value = azurerm_key_vault.kv.vault_uri
}