resource "azurerm_cognitive_account" "cognitiveService" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resourceGroupName
  kind                     = "CognitiveServices"
  sku_name                 = var.sku["name"]
  tags                     = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                       = var.name
  target_resource_id         = azurerm_cognitive_account.cognitiveService.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log {
    category = "Audit"
  }
  enabled_log {
    category = "RequestResponse"
  }
  enabled_log {
    category = "Trace"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "ENRICHMENT-KEY"
  value        = azurerm_cognitive_account.cognitiveService.primary_access_key
  key_vault_id = var.keyVaultId
}


output "cognitiveServicerAccountName" {
  value = azurerm_cognitive_account.cognitiveService.name
}

output "cognitiveServiceID" {
  value = azurerm_cognitive_account.cognitiveService.id
}

output "cognitiveServiceEndpoint" {
  value = azurerm_cognitive_account.cognitiveService.endpoint
}

