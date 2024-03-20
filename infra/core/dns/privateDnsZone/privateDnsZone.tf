resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.dnsname
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link" {
  name                  = var.vnet_link_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = var.resourceGroupName
  virtual_network_id    = var.vnet_resource_id
  registration_enabled  = false
  tags                  = var.tags
}

