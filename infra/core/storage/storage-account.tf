locals {
  config_container_index  = index(var.containers, "config")
  container_arm_file_path = "arm_templates/storage_container/container.template.json"
  queue_arm_file_path     = "arm_templates/storage_queue/queue.template.json"
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
  //public_network_access_enabled = true

  network_rules {  
    default_action             = var.is_secure_mode ? "Deny" : "Allow" 
    //default_action              = "Allow"  
    bypass                     = ["AzureServices"]  
    //ip_rules                   = []  
    virtual_network_subnet_ids = var.is_secure_mode ? [var.subnetResourceId] : []  
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

data "template_file" "container" {
  template = file(local.container_arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

data "template_file" "queue" {
  template = file(local.queue_arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_resource_group_template_deployment" "container" {
  depends_on          = [azurerm_storage_account.storage]
  count               = length(var.containers)
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "storageAccountName" = { value = "${azurerm_storage_account.storage.name}" },
    "location"           = { value = var.location },
    "containerName"      = { value = var.containers[count.index] }
  })
  template_content = data.template_file.container.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "${var.containers[count.index]}-${filemd5(local.container_arm_file_path)}"
  deployment_mode = "Incremental"
}

// Create a storage queue
resource "azurerm_resource_group_template_deployment" "queue" {
  depends_on          = [azurerm_storage_account.storage]
  count               = length(var.queueNames)
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "storageAccountName" = { value = "${azurerm_storage_account.storage.name}" },
    "location"           = { value = var.location },
    "queueName"          = { value = var.queueNames[count.index] }
  })
  template_content = data.template_file.queue.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "${var.queueNames[count.index]}-${filemd5(local.queue_arm_file_path)}"
  deployment_mode = "Incremental"
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

/*
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
}*/

/*
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
}*/

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
  count                  = var.is_secure_mode ? 0 : 1
  name                   = "config.json"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = var.containers[local.config_container_index]
  type                   = "Block"
  source                 = "sp_config/config.json"
}
