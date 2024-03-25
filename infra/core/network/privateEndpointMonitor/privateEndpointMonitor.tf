resource "azurerm_private_endpoint" "private_endpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                       = var.subnetResourceId
  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = var.serviceResourceId
    subresource_names              = [var.groupId]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone_group" "private_dns_zone_group" {
  name                = "${var.groupId}PrivateDnsZoneGroup"
  private_endpoint_id = azurerm_private_endpoint.private_endpoint.id

  private_dns_zone_config {
    name                = "privatelink-monitor-azure-com"
    private_dns_zone_id = var.privateDnsZoneResourceIdMonitor
  }

  private_dns_zone_config {
    name                = "privatelink-oms-opinsights-azure-com"
    private_dns_zone_id = var.privateDnsZoneResourceIdOpsInsightOms
  }

  private_dns_zone_config {
    name                = "privatelink-ods-opinsights-azure-com"
    private_dns_zone_id = var.privateDnsZoneResourceIdOpsInsightOds
  }

  private_dns_zone_config {
    name                = "privatelink-agentsvc-azure-automation-net"
    private_dns_zone_id = var.privateDnsZoneResourceIdAutomation
  }

  private_dns_zone_config {
    name                = "privatelink-blob-core-windows-net"
    private_dns_zone_id = var.privateDnsZoneResourceIdBlob
  }
}

