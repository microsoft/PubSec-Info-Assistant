resource "azurerm_linux_web_app" "app_service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  service_plan_id = var.appServicePlanId
  https_only          = true
  tags                = var.tags

  site_config {
    app_command_line  = var.appCommandLine
    always_on         = var.alwaysOn
    ftps_state        = var.ftpsState
    health_check_path = var.healthCheckPath
    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD" = lower(tostring(var.enableOryxBuild))
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.applicationInsightsConnectionString
      "AZURE_SEARCH_SERVICE_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-SEARCH-SERVICE-KEY)"
      "COSMOSDB_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/COSMOSDB-KEY)"
      "ENRICHMENT_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/ENRICHMENT-KEY)"
      "AZURE_BLOB_STORAGE_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-BLOB-STORAGE-KEY)"
      "BLOB_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BLOB-CONNECTION-STRING)"
      "AZURE_STORAGE_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BLOB-CONNECTION-STRING)"
    }
  )

  identity {
    type = var.managedIdentity ? "SystemAssigned" : "None"
  }
}

data "azurerm_key_vault" "existing" {
  name                = var.keyVaultName
  resource_group_name = var.resourceGroupName
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = data.azurerm_key_vault.existing.id

  tenant_id = azurerm_linux_web_app.app_service.identity.0.tenant_id
  object_id = azurerm_linux_web_app.app_service.identity.0.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "example"
  target_resource_id         = azurerm_linux_web_app.app_service.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log {
    category = "AppServiceAppLogs"
  }
  enabled_log {
    category = "AppServicePlatformLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}


output "name" {
  value = azurerm_linux_web_app.app_service.name
}

output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_linux_web_app.app_service.identity.0.principal_id : ""
}

output "uri" {
  value = "https://${azurerm_linux_web_app.app_service.default_hostname}"
}
