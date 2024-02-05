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
