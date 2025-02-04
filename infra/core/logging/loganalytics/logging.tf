
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

// Create Diagnostic Setting for NSG here since the log analytics workspace is created here after the network is created
resource "azurerm_monitor_diagnostic_setting" "nsg_diagnostic_logs" {
  name                       = var.nsg_name
  target_resource_id         = var.nsg_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id
  enabled_log  {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

// Create Azure Private Link Scope for Azure Monitor
resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "${var.privateLinkScopeName}-pls"
  resource_group_name = var.resourceGroupName
}

// add scoped resource for Log Analytics Workspace
resource "azurerm_monitor_private_link_scoped_service" "ampl-ss_log_analytics" {
  name                = "${var.privateLinkScopeName}-law-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.logAnalytics.id
}


// add scope resoruce for app insights
resource "azurerm_monitor_private_link_scoped_service" "ampl_ss_app_insights" {
  name                = "${var.privateLinkScopeName}-appInsights-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_application_insights.applicationInsights.id
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

// add private endpoint for azure monitor - metrics, app insights, log analytics
resource "azurerm_private_endpoint" "ampls" {
  name                              = "${var.privateLinkScopeName}-private-endpoint"
  location                          = var.location
  resource_group_name               = var.resourceGroupName
  subnet_id                         = data.azurerm_subnet.subnet.id
  custom_network_interface_name     = "infoasstamplsnic"

  private_service_connection {
    name                            = "${var.privateLinkScopeName}-privateserviceconnection"
    private_connection_resource_id  = azurerm_monitor_private_link_scope.ampls.id
    is_manual_connection            = false
    subresource_names               = [var.groupId]
  }

  private_dns_zone_group {
    name                            = "ampls"
    private_dns_zone_ids = [
        azurerm_private_dns_zone.monitor.id,
        azurerm_private_dns_zone.oms.id,
        azurerm_private_dns_zone.ods.id,
        azurerm_private_dns_zone.agentsvc.id,
        var.privateDnsZoneResourceIdBlob
    ]
  }
}

resource "azurerm_private_dns_zone" "monitor" {
  name                = var.privateDnsZoneNameMonitor
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "monitor_api" {
  name                = "api"
  zone_name           = azurerm_private_dns_zone.monitor.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 7)]
}

resource "azurerm_private_dns_a_record" "monitor_global" {
  name                = "global.in.ai"
  zone_name           = azurerm_private_dns_zone.monitor.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 8)]
}

resource "azurerm_private_dns_a_record" "monitor_profiler" {
  name                = "profiler"
  zone_name           = azurerm_private_dns_zone.monitor.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 9)]
}

resource "azurerm_private_dns_a_record" "monitor_live" {
  name                = "live"
  zone_name           = azurerm_private_dns_zone.monitor.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 10)]
}

resource "azurerm_private_dns_a_record" "monitor_snapshot" {
  name                = "snapshot"
  zone_name           = azurerm_private_dns_zone.monitor.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 11)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor-net" {
  name                  = "infoasst-pl-monitor-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone" "oms" {
  name                = var.privateDnsZoneNameOms
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "oms_law_id" {
  name                = "infoasst-pl-oms-law-id"
  zone_name           = azurerm_private_dns_zone.oms.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 4)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms-net" {
  name                  = "infoasst-pl-oms-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.oms.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone" "ods" {
  name                = var.privateDnSZoneNameOds
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "ods_law_id" {
  name                = "infoasst_pl_ods_law_id"
  zone_name           = azurerm_private_dns_zone.ods.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 5)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods-net" {
  name                  = "infoasst-pl-ods-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.ods.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone" "agentsvc" {
  name                = var.privateDnsZoneNameAutomation
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_dns_a_record" "agentsvc_law_id" {
  name                = "infoasst_pl_agentsvc_law_id"
  zone_name           = azurerm_private_dns_zone.agentsvc.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 6)]
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc-net" {
  name                  = "infoasst-pl-agentsvc-net"
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_a_record" "blob_scadvisorcontentpld" {
  name                = "scadvisorcontentpl"
  zone_name           = var.privateDnsZoneNameBlob
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records             = [cidrhost(var.ampls_subnet_CIDR, 12)]
}