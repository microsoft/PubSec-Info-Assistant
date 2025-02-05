# Create the web app service plan
resource "azurerm_service_plan" "appServicePlan" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resourceGroupName

  sku_name     = var.sku["size"]
  worker_count = var.sku["capacity"]
  
  os_type = "Linux"
  
  zone_balancing_enabled = true

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
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.appServicePlan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
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
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.appServicePlan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 20
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
  name                                           = var.name
  location                                       = var.location
  resource_group_name                            = var.resourceGroupName
  service_plan_id                                = azurerm_service_plan.appServicePlan.id
  https_only                                     = true
  tags                                           = merge(var.tags, { "azd-service-name" = "${var.name}" })
  webdeploy_publish_basic_authentication_enabled = false
  public_network_access_enabled                  = true
  virtual_network_subnet_id                      = var.snetIntegration_id


  site_config {

    application_stack {
      python_version = var.runtimeVersion
    }
    always_on                               = var.alwaysOn
    ftps_state                              = "Disabled"
    app_command_line                        = var.appCommandLine
    health_check_path                       = var.healthCheckPath
    health_check_eviction_time_in_min       = 10

    cors {
      allowed_origins = concat([var.azure_portal_domain, "https://ms.portal.azure.com"], var.allowedOrigins)
    }

    scm_ip_restriction {
      ip_address = "${var.scm_public_ip}/32"
      action     = "Allow"
      priority   = 100
      name       = "DeploymentMachine"
    }
    scm_ip_restriction {
      ip_address  = "0.0.0.0/0"
      action      = "Deny"
      priority    = 2147483647
      name        = "Deny all"
      description = "Deny all access"
    }

    scm_ip_restriction_default_action = "Deny"
    scm_use_main_ip_restriction       = false
  }

  identity {
    type = var.managedIdentity ? "SystemAssigned" : "None"
  }


  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT"        = lower(tostring(var.scmDoBuildDuringDeployment))
      "ENABLE_ORYX_BUILD"                     = lower(tostring(var.enableOryxBuild))
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.applicationInsightsConnectionString
      "BING_SEARCH_KEY"                       = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BINGSEARCH-KEY)"
      "WEBSITES_PORT"                         = "6000"
      "WEBSITES_CONTAINER_START_TIME_LIMIT"   = "1600"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
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
    auth_enabled           = true
    default_provider       = "azureactivedirectory"
    runtime_version        = "~2"
    unauthenticated_action = "RedirectToLoginPage"
    require_https          = true
    active_directory_v2 {
      client_id                   = var.aadClientId
      login_parameters            = {}
      tenant_auth_endpoint        = "https://${var.azure_sts_issuer_domain}/${var.tenantId}/v2.0"
      www_authentication_disabled = false
      allowed_audiences = [
        "api://${var.name}"
      ]
    }
    login {
      token_store_enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_commercial" {
  count                      = var.azure_environment == "AzureUSGovernment" ? 0 : 1
  name                       = azurerm_linux_web_app.app_service.name
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

  enabled_log {
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

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "backendPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  tags                          = var.tags
  custom_network_interface_name = "infoasstwebnic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_linux_web_app.app_service.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}
