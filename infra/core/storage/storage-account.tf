locals {
  container_arm_file_path = "arm_templates/storage_container/container.template.json"
  queue_arm_file_path     = "arm_templates/storage_queue/queue.template.json"
}

resource "azurerm_storage_account" "storage" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resourceGroupName
  tags                            = var.tags
  account_tier                    = var.sku.name
  account_replication_type        = "LRS"
  access_tier                     = var.accessTier
  min_tls_version                 = var.minimumTlsVersion
  https_traffic_only_enabled      = true
  public_network_access_enabled   = var.is_secure_mode ? false : true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true #var.is_secure_mode ? false : true # This will need to be enabled once the Azure Functions can support Entra ID auth

  network_rules {  
    default_action                = var.is_secure_mode ? "Deny" : "Allow"
    bypass                        = ["AzureServices"]  
    ip_rules                      = []  
    virtual_network_subnet_ids    = var.is_secure_mode ? var.network_rules_allowed_subnets : []  
  }
  
  blob_properties{
    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "PUT", "OPTIONS", "POST", "PATCH", "HEAD"]
        allowed_origins = ["*"]
        exposed_headers = ["*"]
        max_age_in_seconds = 86400
    }
      
    delete_retention_policy {
      days = 7
    }
        
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  name                       = azurerm_storage_account.storage.name
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  metric {
    category = "Capacity"
    enabled  = true
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "blob_diagnostic_logs" {
  name                       = "${azurerm_storage_account.storage.name}-blob"
  target_resource_id         = "${azurerm_storage_account.storage.id}/blobServices/default"
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  metric {
    category = "Capacity"
    enabled  = true
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "file_diagnostic_logs" {
  name                       = "${azurerm_storage_account.storage.name}-file"
  target_resource_id         = "${azurerm_storage_account.storage.id}/fileServices/default"
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "queue_diagnostic_logs" {
  name                       = "${azurerm_storage_account.storage.name}-queue"
  target_resource_id         = "${azurerm_storage_account.storage.id}/queueServices/default"
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "table_diagnostic_logs" {
  name                       = "${azurerm_storage_account.storage.name}-table"
  target_resource_id         = "${azurerm_storage_account.storage.id}/tableServices/default"
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  metric {
    category = "Transaction"
    enabled  = true
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
    "publicNetworkAccess" = { value = var.is_secure_mode ? "Disabled" : "Enabled" }
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
    "publicNetworkAccess" = { value = var.is_secure_mode ? "Disabled" : "Enabled" }
  })
  template_content = data.template_file.queue.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "${var.queueNames[count.index]}-${filemd5(local.queue_arm_file_path)}"
  deployment_mode = "Incremental"
}

module "storage_connection_string" {
  source                        = "../security/keyvaultSecret"
  resourceGroupName             = var.resourceGroupName
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = var.key_vault_name
  secret_name                   = "AZURE-STORAGE-CONNECTION-STRING"
  secret_value                  = azurerm_storage_account.storage.primary_connection_string
  tags                          = var.tags
  alias                         = "blobconnstring"
  kv_secret_expiration          = var.kv_secret_expiration
  contentType                   = "application/vnd.ms-StorageConnectionString"
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "blobPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint-blob"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
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
  subnet_id                     = data.azurerm_subnet.subnet[0].id
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
  subnet_id                     = data.azurerm_subnet.subnet[0].id
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
  subnet_id                     = data.azurerm_subnet.subnet[0].id
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

// Only create the config blob if we are not in secure mode as SharePoint integration is not supported in secure mode
resource "azurerm_storage_blob" "config" {
  depends_on = [ azurerm_resource_group_template_deployment.container ]
  count                  = var.is_secure_mode ? 0 : 1
  name                   = "config.json"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = "config"
  type                   = "Block"
  source                 = "sp_config/config.json"
}
