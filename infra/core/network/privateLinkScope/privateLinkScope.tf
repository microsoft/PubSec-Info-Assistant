// Create Azure Private Link Scope for Azure Monitor

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "${var.name}-ampls"
  resource_group_name = var.resourceGroupName
}

// add scoped resource for Log Analytics Workspace

resource "azurerm_monitor_private_link_scoped_service" "ampl-ss_log_analytics" {
  name                = "${var.name}-law-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = var.workspaceId
}


// add scope resoruce for app insights

resource "azurerm_monitor_private_link_scoped_service" "ampl_ss_app_insights" {
  name                = "${var.name}-amplsservice"
  resource_group_name = "${var.name}-appInsights-connection"
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = var.appInsightsId
}

//// add private endpoint for azure monitor - metrics, app insights, log analytics

resource "azurerm_private_endpoint" "azureMonitorPrivateEndpoint" {
  name                              = "${var.name}-private-endpoint"
  location                          = var.location
  resource_group_name               = var.resourceGroupName
  subnet_id                         = var.subnetResourceId
  custom_network_interface_name     = "'${var.name}-network-interface'"

  private_service_connection {
    name                            = "${var.name}-private-link-service-connection"
    private_connection_resource_id  = azurerm_monitor_private_link_scope.ampls.id
    is_manual_connection            = false
    subresource_names               = [var.groupId]
  }

  private_dns_zone_group {
    name                            = "${var.groupId}PrivateDnsZoneGroup"
    private_dns_zone_ids = [
        var.privateDnsZoneResourceIdMonitor,
        var.privateDnsZoneResourceIdOpsInsightOms,
        var.privateDnsZoneResourceIdOpsInsightOds,
        var.privateDnsZoneResourceIdAutomation,
        var.privateDnsZoneResourceIdBlob
    ]
  }
}
