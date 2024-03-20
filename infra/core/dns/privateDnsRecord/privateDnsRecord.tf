
resource "azurerm_private_dns_a_record" "dnsRecord" {
  name                = var.hostname
  zone_name           = azurerm_private_dns_zone.privateDnsZoneName.name
  resource_group_name = var.resourceGroupName
  ttl                 = 3600
  records            = [var.ipAddress]
}

resource "azurerm_private_endpoint_dns_zone_group" "PrivateDnsZoneGroup" {
  count = var.reusePrivateDnsZone ? 0 : 1

  name                = "${var.groupId}PrivateDnsZoneGroup"
  private_endpoint_id = data.azurerm_private_endpoint[0].privateEndpointName.id
  private_dns_zone_id = data.azurerm_private_dns_zone[0].privateDnsZoneName.id
}


