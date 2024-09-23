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

resource "azurerm_role_assignment" "acr_pull_role" {
  principal_id         = azurerm_linux_web_app.app_service.identity.0.principal_id
  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
}

# Create the web app
resource "azurerm_linux_web_app" "app_service" {
  name                                = var.name
  location                            = var.location
  resource_group_name                 = var.resourceGroupName
  service_plan_id                     = azurerm_service_plan.appServicePlan.id
  https_only                          = true
  tags                                = var.tags
  webdeploy_publish_basic_authentication_enabled = false
  public_network_access_enabled                   = true
  virtual_network_subnet_id                       = var.is_secure_mode ? var.snetIntegration_id : null
  
  site_config {
    application_stack {
      docker_image_name         = "${var.container_registry}/webapp:latest"
      docker_registry_url       = "https://${var.container_registry}"
      docker_registry_username  = var.container_registry_admin_username
      docker_registry_password  = var.container_registry_admin_password
    }
    container_registry_use_managed_identity = true
    always_on                               = var.alwaysOn
    ftps_state                              = var.is_secure_mode ? "Disabled" : var.ftpsState
    app_command_line                        = var.appCommandLine
    health_check_path                       = var.healthCheckPath
    health_check_eviction_time_in_min       = 10

    cors {
      allowed_origins = concat([var.azure_portal_domain, "https://ms.portal.azure.com"], var.allowedOrigins)
    }

  }

  identity {
    type = var.managedIdentity ? "SystemAssigned" : "None"
  }
  
  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT"            = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD"                         = lower(tostring(var.enableOryxBuild))
      "APPLICATIONINSIGHTS_CONNECTION_STRING"     = var.applicationInsightsConnectionString
      "BING_SEARCH_KEY"                           = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BINGSEARCH-KEY)"
      "WEBSITE_PULL_IMAGE_OVER_VNET"              = var.is_secure_mode ? "true" : "false"
      "WEBSITES_PORT"                             = "6000"
      "WEBSITES_CONTAINER_START_TIME_LIMIT"       = "1600"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE"       = "false"
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
    failed_request_tracing = true
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

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_commercial" {
  count                      = var.azure_environment == "AzureUSGovernment" ? 0 : 1
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
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }
  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceAuditLogs"
  }
  enabled_log {
    category = "AppServiceAuthenticationLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_usgov" {
  count                      = var.azure_environment == "AzureUSGovernment" ? 1 : 0
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
  
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceFileAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
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

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "backendPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
  tags                          = var.tags
  custom_network_interface_name = "infoasstwebnic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_linux_web_app.app_service.id
    is_manual_connection           = false
    subresource_names               = ["sites"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}