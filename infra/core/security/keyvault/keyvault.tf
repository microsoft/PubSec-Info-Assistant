data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resourceGroupName // Replace with your resource group name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  tags                        = var.tags
  enabled_for_template_deployment = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                            = var.name
  target_resource_id              = azurerm_key_vault.kv.id
  log_analytics_workspace_id      = var.logAnalyticsWorkspaceResourceId

  enabled_log {
    category = "AuditEvent"
  }
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_key_vault_access_policy" "infoasst" {
  depends_on  = [
    azurerm_key_vault.kv
  ]
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.kvAccessObjectId
 
  key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
      "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
      "Verify", "WrapKey"
    ]
 
  secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
}

resource "azurerm_key_vault_secret" "spClientKeySecret" {
  depends_on  = [
    azurerm_key_vault_access_policy.infoasst,
    azurerm_key_vault.kv
  ]
  name         = "AZURE-CLIENT-SECRET"
  value        = var.spClientSecret
  key_vault_id = azurerm_key_vault.kv.id
}

output "keyVaultName" {
  value = azurerm_key_vault.kv.name
}

output "keyVaultId" {
  value = azurerm_key_vault.kv.id
}

output "keyVaultUri" {
  value = azurerm_key_vault.kv.vault_uri
}