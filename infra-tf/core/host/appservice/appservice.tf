


resource "azurerm_linux_web_app" "app_service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  service_plan_id = var.appServicePlanId
  https_only          = true

  site_config {
    application_stack {
      python_version = "3.10"
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
    var.app_settings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD"              = tostring(var.enableOryxBuild)
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.applicationInsightsConnectionString
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


resource "azurerm_key_vault" "key_vault" {
  count               = var.keyVaultName != "" ? 1 : 0
  name                = var.keyVaultName
  location            = var.location
  resource_group_name = var.resourceGroupName
  tenant_id           = var.tenantId
  sku_name            = "standard"
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

output "name" {
  value = azurerm_linux_web_app.app_service.name
}

output "uri" {
  value = "https://${azurerm_linux_web_app.app_service.default_hostname}"
}
