resource "azurerm_app_service" "app_service" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  app_service_plan_id = var.appServicePlanId
  https_only          = true
  tags                = var.tags

  site_config {
    always_on        = var.alwaysOn
    linux_fx_version = var.linuxFxVersion
    ftps_state       = var.ftpsState
    health_check_path = var.healthCheckPath
    min_tls_version  = "1.2"
  }

  app_settings = merge(
    var.appSettings,
    {
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = var.scmDoBuildDuringDeployment
      "ENABLE_ORYX_BUILD" = var.enableOryxBuild
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.applicationInsightsConnectionString
    }
  )

  identity {
    type = var.managedIdentity ? "SystemAssigned" : "None"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "example"
  target_resource_id         = azurerm_app_service.app_service.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  log {
    category = "AppServiceAppLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 0
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 0
    }
  }
}

output "name" {
  value = azurerm_app_service.app_service.name
}

output "identity_principal_id" {
  value = var.managedIdentity ? azurerm_app_service.app_service.identity.0.principal_id : ""
}

output "uri" {
  value = "https://${azurerm_app_service.app_service.default_site_hostname}"
}
