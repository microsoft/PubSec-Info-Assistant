resource "azurerm_private_dns_zone" "pr_dns_zone" {
  name                = var.name
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "pr_dns_vnet_link" {
  name                  = var.vnetLinkName
  resource_group_name   = var.resourceGroupName
  private_dns_zone_name = azurerm_private_dns_zone.pr_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}
