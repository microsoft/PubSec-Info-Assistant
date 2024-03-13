locals {
  config_container_index = index(var.containers, "config")
}


resource "azurerm_storage_account" "storage" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resourceGroupName
  account_tier             = var.sku.name
  account_replication_type = "LRS"
  access_tier              = var.accessTier
  min_tls_version          = var.minimumTlsVersion
  enable_https_traffic_only = true

  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
  }

  tags = var.tags

   blob_properties{
    cors_rule{
        allowed_headers = ["*"]
        allowed_methods = ["GET", "PUT", "OPTIONS", "POST", "PATCH", "HEAD"]
        allowed_origins = ["*"]
        exposed_headers = ["*"]
        max_age_in_seconds = 86400
        }
    }
}



resource "azurerm_storage_container" "container" {
  count = length(var.containers)
  name                  = var.containers[count.index]
  storage_account_name  = azurerm_storage_account.storage.name
}

resource "azurerm_storage_queue" "queue" {
  count                = length(var.queueNames)
  name                 = var.queueNames[count.index]
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "BLOB-CONNECTION-STRING"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = var.keyVaultId
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "AZURE-BLOB-STORAGE-KEY"
  value        = azurerm_storage_account.storage.primary_access_key
  key_vault_id = var.keyVaultId
}

resource "azurerm_storage_blob" "config" {
  name                   = "config.json"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container[local.config_container_index].name
  type                   = "Block"
  source                 = "config/config.json"
}

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

