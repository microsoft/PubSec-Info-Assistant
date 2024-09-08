
resource "azurerm_search_service" "search" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.sku["name"]
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = true
  replica_count                 = 1
  partition_count               = 1
  semantic_search_sku           = var.semanticSearch 
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                            = var.name
  target_resource_id              = azurerm_search_service.search.id
  log_analytics_workspace_id      = var.logAnalyticsWorkspaceResourceId

  enabled_log {
    category = "OperationLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "AZURE-SEARCH-SERVICE-KEY"
  value        = data.azurerm_search_service.search.primary_key
  key_vault_id = var.keyVaultId
}

output "id" {
  value = azurerm_search_service.search.id
}

output "endpoint" {
  value = "https://${azurerm_search_service.search.name}.${var.azure_search_domain}/"
}

output "name" {
  value = azurerm_search_service.search.name
}

data "azurerm_search_service" "search" {
  name                = azurerm_search_service.search.name
  resource_group_name = var.resourceGroupName
}
