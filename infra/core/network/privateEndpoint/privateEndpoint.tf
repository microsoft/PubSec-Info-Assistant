resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.groupId # Assumed groupId is the resource group name
  subnet_id           = var.subnetResourceId

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = var.serviceResourceId
    subresource_names              = [var.groupId]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}
