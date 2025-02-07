locals {
  container_arm_file_path = "arm_templates/storage_container/container.template.json"
  queue_arm_file_path     = "arm_templates/storage_queue/queue.template.json"
  nsp_arm_file_path = "arm_templates/network_security_perimeter/nsp_assoc.template.json"
}

# Create the NSP Association via ARM Template
data "template_file" "workflow" {
  template = file(local.nsp_arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_storage_account" "storage" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resourceGroupName
  tags                            = var.tags
  account_tier                    = var.sku.name
  account_replication_type        = "ZRS"
  access_tier                     = var.accessTier
  min_tls_version                 = var.minimumTlsVersion
  https_traffic_only_enabled      = true
  public_network_access_enabled   = true // enabled but protected by network security perimeter (NSP)
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  local_user_enabled              = false

  network_rules {  
    default_action                = "Deny"
    bypass                        = ["AzureServices"]  
    ip_rules                      = var.deployment_machine_ip
    virtual_network_subnet_ids    = var.network_rules_allowed_subnets
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

resource "azurerm_resource_group_template_deployment" "container" {
  depends_on          = [azurerm_storage_account.storage]
  count               = length(var.containers)
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "storageAccountName" = { value = "${azurerm_storage_account.storage.name}" },
    "location"           = { value = var.location },
    "containerName"      = { value = var.containers[count.index] }
    "publicNetworkAccess" = { value = "Disabled" }
  })
  template_content = data.template_file.container.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "${var.containers[count.index]}-${filemd5(local.container_arm_file_path)}"
  deployment_mode = "Incremental"
}

//Create the Network Security Perimeter Associatoin
resource "azurerm_resource_group_template_deployment" "nsp_assoc_w_storage" {
  count                         = var.useNetworkSecurityPerimeter ? 1 : 0
  resource_group_name           = var.resourceGroupName
  parameters_content            = jsonencode({
    "name"                      = { value = "${var.nsp_assoc_name}" },
    "nsp_name"                  = { value = "${var.nsp_name}" },
    "location"                  = { value = "${var.location}" },
    "tags"                      = { value = var.tags },
    "profileId"                 = { value = "${var.nsp_profile_id}" },
    "privateLinkResourceId"     = { value = azurerm_storage_account.storage.id }, 
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name                          = "nsp-assoc-storage-${filemd5(local.nsp_arm_file_path)}"
  deployment_mode               = "Incremental"
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "blobPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint-blob"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
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

  depends_on = [ azurerm_storage_account.storage ]
}

// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "filePrivateEndpoint" {
  name                          = "${var.name}-private-endpoint-file"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
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
  
  depends_on = [ azurerm_storage_account.storage ]
}


// Create a private endpoint for blob storage account
resource "azurerm_private_endpoint" "tablePrivateEndpoint" {
  name                          = "${var.name}-private-endpoint-table"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
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

  depends_on = [ azurerm_storage_account.storage ]
}

// Create a private endpoint for queue storage account
resource "azurerm_private_endpoint" "queuePrivateEndpoint" {
  name                          = "${var.name}-private-endpoint-queue"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
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

  depends_on = [ azurerm_storage_account.storage ]
}