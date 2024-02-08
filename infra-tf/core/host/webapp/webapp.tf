
# Create the web app service plan
resource "azurerm_service_plan" "appServicePlan" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resourceGroupName

  sku_name = var.sku["size"]
  worker_count = var.sku["capacity"]
  os_type = "Linux"

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "scaleout" {
  name                = azurerm_service_plan.appServicePlan.name
  resource_group_name = var.resourceGroupName
  location            = var.location
  target_resource_id  = azurerm_service_plan.appServicePlan.id

  profile {
    name = "Scale out condition"
    capacity {
      default = 1
      minimum = 1
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.appServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "GreaterThan"
        threshold           = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.appServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT10M"
        time_aggregation    = "Average"
        operator            = "LessThan"
        threshold           = 20
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT15M"
      }
    }
  }
}



# Create the web app
resource "azurerm_linux_web_app" "app_service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  service_plan_id = azurerm_service_plan.appServicePlan.id
  https_only          = true

  site_config {
    application_stack {
      python_version = var.runtimeVersion
    }
    always_on                      = var.alwaysOn
    ftps_state                     = var.ftpsState
    app_command_line               = var.appCommandLine
    health_check_path              = var.healthCheckPath
    cors {
      allowed_origins = concat([var.portalURL, "https://ms.portal.azure.com"], var.allowedOrigins)
    }
  }

  identity {
    type = var.managedIdentity ? "SystemAssigned" : "None"
  }
 
  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD"              = lower(tostring(var.enableOryxBuild))
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.applicationInsightsConnectionString
      "AZURE_SEARCH_SERVICE_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-SEARCH-SERVICE-KEY)"
      "COSMOSDB_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/COSMOSDB-KEY)"
      "AZURE_BLOB_STORAGE_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-BLOB-STORAGE-KEY)"
      "ENRICHMENT_KEY" = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/ENRICHMENT-KEY)"
    }
  )

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
    http_logs {
      file_system {
        retention_in_days = 1
        retention_in_mb   = 35
      }
    }
  }

  auth_settings_v2 {
    auth_enabled = true
    default_provider = "azureactivedirectory"
    runtime_version = "~2"
    unauthenticated_action = "RedirectToLoginPage"
    require_https = true
    active_directory_v2{
      client_id = var.aadClientId
      login_parameters = {}
      tenant_auth_endpoint = "https://sts.windows.net/${var.tenantId}/v2.0"
      www_authentication_disabled  = false
      allowed_audiences = [
        "api://${var.name}"
      ]
    }
    login{
      token_store_enabled = false
    }
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


resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  name                       = azurerm_linux_web_app.app_service.name
  target_resource_id         = azurerm_linux_web_app.app_service.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log  {
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

output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_linux_web_app.app_service.identity.0.principal_id : ""
}

output "web_app_name" {
  value = azurerm_linux_web_app.app_service.name
}

output "uri" {
  value = "https://${azurerm_linux_web_app.app_service.default_hostname}"
}

output "web_serviceplan_name" {
  value = azurerm_service_plan.appServicePlan.name
}
