


resource "azurerm_app_service" "app_service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  app_service_plan_id = var.appServicePlanId
  https_only          = true

  site_config {
    linux_fx_version               = var.linuxFxVersion
    always_on                      = var.alwaysOn
    ftps_state                     = var.ftpsState
    app_command_line               = var.appCommandLine
    number_of_workers              = var.numberOfWorkers != -1 ? var.numberOfWorkers : 1
    # minimum_elastic_instance_count = var.minimumElasticInstanceCount != -1 ? var.minimumElasticInstanceCount : 1
    use_32_bit_worker_process      = var.use32BitWorkerProcess
    # function_app_scale_limit       = var.functionAppScaleLimit != -1 ? var.functionAppScaleLimit : null
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
    detailed_error_messages_enabled = true
    failed_request_tracing_enabled  = true
    http_logs {
      file_system {
        retention_in_days = 1
        retention_in_mb   = 35
      }
    }
  }

  auth_settings {
    enabled = true
    default_provider = "AzureActiveDirectory"
    issuer = "https://sts.windows.net/${var.tenantId}/v2.0"
    active_directory {
      client_id = var.aadClientId
      allowed_audiences = [
        "api://${var.name}"
      ]
    }
  }
}

# resource "azurerm_app_service_auth_settings" "auth_settings" {
#   resource_group_name = var.resourceGroupName
#   app_service_name    = azurerm_app_service.app_service.name

#   enabled = true

#   unauthenticated_client_action = "RedirectToLoginPage"
#   token_store_enabled           = true

#   active_directory {
#     client_id     = var.aadClientId
#     client_secret = var.aadClientSecret
#   }

#   allowed_external_redirect_urls = [
#     "api://${azurerm_app_service.app_service.name}"
#   ]
# }

resource "azurerm_key_vault" "key_vault" {
  count               = var.keyVaultName != "" ? 1 : 0
  name                = var.keyVaultName
  location            = var.location
  resource_group_name = var.resourceGroupName
  tenant_id           = var.tenantId
  sku_name            = "standard"
}


resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  name                       = azurerm_app_service.app_service.name
  target_resource_id         = azurerm_app_service.app_service.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  log {
    category = "AppServiceAppLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = true
    }
  }

  log {
    category = "AppServicePlatformLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = true
    }
  }

  log {
    category = "AppServiceConsoleLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = true
    }
  }
}

output "identityPrincipalId" {
  value = var.managedIdentity ? azurerm_app_service.app_service.identity.0.principal_id : ""
}

output "name" {
  value = azurerm_app_service.app_service.name
}

output "uri" {
  value = "https://${azurerm_app_service.app_service.default_site_hostname}"
}
