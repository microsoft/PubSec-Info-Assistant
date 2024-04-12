
resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = var.logAnalyticsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.skuName
  tags                = var.tags
  retention_in_days   = 30
}

resource "azurerm_application_insights" "applicationInsights" {
  name                = var.applicationInsightsName
  location            = var.location
  resource_group_name = var.resourceGroupName
  application_type    = "web"
  tags                = var.tags
  workspace_id        = azurerm_log_analytics_workspace.logAnalytics.id
}

// Diagnostic Settings Data Source
data "azurerm_monitor_diagnostic_categories" "web_app" {
  resource_id = azurerm_application_insights.applicationInsights.id
}

// Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "activity_log_diagnostic_setting" {
  name                        = "${var.logAnalyticsName}-DS"
  target_resource_id          = azurerm_application_insights.applicationInsights.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.logAnalytics.id
 
  dynamic "metric" {
  for_each = data.azurerm_monitor_diagnostic_categories.web_app.metrics
  content {
    category = metric.value
    enabled  = true
    }
  }

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.web_app.log_category_groups
    content {
      category = log.value
      enabled  = true
    }
  }

  depends_on = [azurerm_log_analytics_workspace.logAnalytics]
}

// Create Azure Private Link Scope for Azure Monitor
resource "azurerm_monitor_private_link_scope" "ampls" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-pls"
  resource_group_name = var.resourceGroupName
}

// add scoped resource for Log Analytics Workspace
resource "azurerm_monitor_private_link_scoped_service" "ampl-ss_log_analytics" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-law-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls[0].name
  linked_resource_id  = azurerm_log_analytics_workspace.logAnalytics.id
}


// add scope resoruce for app insights
resource "azurerm_monitor_private_link_scoped_service" "ampl_ss_app_insights" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.privateLinkScopeName}-appInsights-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls[0].name
  linked_resource_id  = azurerm_application_insights.applicationInsights.id
}

// Get the virtual network that was set up
data "azurerm_virtual_network" "vnet" {
  count               = var.is_secure_mode ? 1 : 0
  name                = var.vnetName
  resource_group_name = var.resourceGroupName
}

// Get the subnet that was set up for Azure Monitor
data "azurerm_subnet" "ampls" {
  count               = var.is_secure_mode ? 1 : 0
  name                 = "ampls"
  virtual_network_name = var.vnetName
  resource_group_name  = var.resourceGroupName
}

//// add private endpoint for azure monitor - metrics, app insights, log analytics
resource "azurerm_private_endpoint" "ampls" {
  count                             = var.is_secure_mode ? 1 : 0
  name                              = "${var.privateLinkScopeName}-private-endpoint"
  location                          = var.location
  resource_group_name               = var.resourceGroupName
  subnet_id                         = data.azurerm_subnet.ampls[0].id
  custom_network_interface_name     = "infoasstamplsnic"

  private_service_connection {
    name                            = "${var.privateLinkScopeName}-privateserviceconnection"
    private_connection_resource_id  = azurerm_monitor_private_link_scope.ampls[0].id
    is_manual_connection            = false
    subresource_names               = [var.groupId]
  }

  private_dns_zone_group {
    name                            = "ampls"
    private_dns_zone_ids = [
        azurerm_private_dns_zone.monitor[0].id,
        azurerm_private_dns_zone.oms[0].id,
        azurerm_private_dns_zone.ods[0].id,
        azurerm_private_dns_zone.agentsvc[0].id,
        var.privateDnsZoneResourceIdBlob
    ]
  }
}

resource "azurerm_private_dns_zone" "monitor" {
  count               = var.is_secure_mode ? 1 : 0
  name                = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "monitor_api" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "api"
  zone_name           = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 7)]
}

resource "azurerm_private_dns_a_record" "monitor_global" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "global.in.ai"
  zone_name           = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 8)]
}

resource "azurerm_private_dns_a_record" "monitor_profiler" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "profiler"
  zone_name           = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 9)]
}

resource "azurerm_private_dns_a_record" "monitor_live" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "live"
  zone_name           = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 10)]
}

resource "azurerm_private_dns_a_record" "monitor_snapshot" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "snapshot"
  zone_name           = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 11)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor-net" {
  count               = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-monitor-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.monitor[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_dns_zone" "oms" {
  count               = var.is_secure_mode ? 1 : 0
  name                = var.privateDnsZoneNameOms
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "oms_law_id" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst-pl-oms-law-id"
  zone_name           = azurerm_private_dns_zone.oms[0].name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 4)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms-net" {
  count               = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-oms-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.oms[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_dns_zone" "ods" {
  count               = var.is_secure_mode ? 1 : 0
  name                = var.privateDnSZoneNameOds
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "ods_law_id" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst_pl_ods_law_id"
  zone_name           = azurerm_private_dns_zone.ods[0].name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 5)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods-net" {
  count               = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-ods-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.ods[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_dns_zone" "agentsvc" {
  count               = var.is_secure_mode ? 1 : 0
  name                = var.privateDnsZoneNameAutomation
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "agentsvc_law_id" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "infoasst_pl_agentsvc_law_id"
  zone_name           = azurerm_private_dns_zone.agentsvc[0].name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 6)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc-net" {
  count               = var.is_secure_mode ? 1 : 0
  name                  = "infoasst-pl-agentsvc-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_dns_a_record" "blob_scadvisorcontentpld" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "scadvisorcontentpl"
  zone_name           = var.privateDnsZoneNameBlob
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(data.azurerm_subnet.ampls[0].address_prefixes[0], 12)]
}