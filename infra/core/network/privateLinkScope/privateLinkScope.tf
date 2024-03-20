resource "azurerm_monitor_private_link_scope" "pls" {
  name                = var.name
  resource_group_name = var.resourceGroupName
}

// add scoped resource for law

resource "azurerm_monitor_private_link_scoped_service" "pls_ss_log_analytics" {
  name                = "${var.name}-law-connection"
  resource_group_name = var.resourceGroupName
  scope_name          = azurerm_monitor_private_link_scope.pls.name
  linked_resource_id  = var.workspaceId
}


// add scope resoruce for app insights

resource "azurerm_monitor_private_link_scoped_service" "pls_ss_app_insights" {
  name                = "example-amplsservice"
  resource_group_name = "${var.name}-appInsights-connection"
  scope_name          = azurerm_monitor_private_link_scope.pls.name
  linked_resource_id  = var.appInsightsId
}

//

resource "azurerm_private_endpoint" "private_endpoint" {
  name                              = "${var.name}-private-endpoint"
  location                          = var.location
  resource_group_name               = var.resourceGroupName
  subnet_id                         = var.subnetResourceId
  custom_network_interface_name     = "'${var.name}-network-interface'"

  private_service_connection {
    name                            = "${var.name}-private-link-service-connection"
    private_connection_resource_id  = azurerm_monitor_private_link_scope.pls.id
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