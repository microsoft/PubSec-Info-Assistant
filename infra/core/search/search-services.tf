
resource "azurerm_search_service" "search" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  sku                           = var.sku["name"]
  tags                          = var.tags
  public_network_access_enabled = var.is_secure_mode ? false : true
  local_authentication_enabled  = false
  replica_count                 = 1
  partition_count               = 1
  semantic_search_sku           = var.semanticSearch 

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "searchPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
  custom_network_interface_name = "infoasstsearchnic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}