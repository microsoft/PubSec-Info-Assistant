data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resourceGroupName // Replace with your resource group name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.kvAccessObjectId

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", 
      "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", 
      "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }
}

resource "azurerm_key_vault_secret" "searchServiceKeySecret" {
  name         = "AZURE-SEARCH-SERVICE-KEY"
  value        = var.searchServiceKey
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "openaiServiceKeySecret" {
  name         = "AZURE-OPENAI-SERVICE-KEY"
  value        = var.openaiServiceKey
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmosdbKeySecret" {
  name         = "COSMOSDB-KEY"
  value        = var.cosmosdbKey
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "formRecognizerKeySecret" {
  name         = "AZURE-FORM-RECOGNIZER-KEY"
  value        = var.formRecognizerKey
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "blobConnectionStringSecret" {
  name         = "BLOB-CONNECTION-STRING"
  value        = var.blobConnectionString
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "enrichmentKeySecret" {
  name         = "ENRICHMENT-KEY"
  value        = var.enrichmentKey
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "spClientKeySecret" {
  name         = "AZURE-CLIENT-SECRET"
  value        = var.spClientSecret
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "blobStorageKeySecret" {
  name         = "AZURE-BLOB-STORAGE-KEY"
  value        = var.blobStorageKey
  key_vault_id = azurerm_key_vault.kv.id
}

output "keyVaultName" {
  value = azurerm_key_vault.kv.name
}
