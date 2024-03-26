locals {
  config_container_index = index(var.containers, "config")
}


// Create a storage account
resource "azurerm_storage_account" "storage" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  account_tier                  = var.sku.name
  account_replication_type      = "LRS"
  access_tier                   = var.accessTier
  min_tls_version               = var.minimumTlsVersion
  enable_https_traffic_only     = true
  public_network_access_enabled = var.is_secure_mode ? false : true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "PUT", "OPTIONS", "POST", "PATCH", "HEAD"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 86400
    }
  }
}

// Create a storage container
resource "azapi_resource" "containers" {
  count                = length(var.containers)
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01"
  name      = var.containers[count.index]
  parent_id = "${azurerm_storage_account.storage.id}/blobServices/default"
  body = jsonencode({
    properties = {
      publicAccess                = "None"
    }
  })
  depends_on = [
    azurerm_storage_account.storage
  ]
}

// Create a storage queue
resource "azapi_resource" "queues" {
  count = length(var.queueNames)
  type = "Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01"
  name = var.queueNames[count.index]
  parent_id = "${azurerm_storage_account.storage.id}/queueServices/default"
  body = jsonencode({
    properties = {
      metadata = {}
    }
  })
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

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "blobPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint-blob"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnetResourceId
  custom_network_interface_name = "infoasstblobstoragenic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "filePrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint-file"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnetResourceId
  custom_network_interface_name = "infoasstfilestoragenic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "tablePrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint-table"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnetResourceId
  custom_network_interface_name = "infoassttablestoragenic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}

// Create a private endpoint for queue storage account
resource "azurerm_private_endpoint" "queuePrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint-queue"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnetResourceId
  custom_network_interface_name = "infoasstqueuestoragenic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}


resource "azurerm_storage_blob" "config" {
  name                   = "config.json"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = var.containers[local.config_container_index]
  type                   = "Block"
  source                 = "sp_config/config.json"
}
