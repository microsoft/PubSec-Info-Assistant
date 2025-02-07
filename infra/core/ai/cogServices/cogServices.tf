resource "azurerm_cognitive_account" "cognitiveService" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "CognitiveServices"
  sku_name                      = var.sku["name"]
  tags                          = var.tags
  custom_subdomain_name         = var.name
  public_network_access_enabled = false
  local_auth_enabled            = false
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "accountPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  custom_network_interface_name = "infoasstazureainic"


  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_cognitive_account.cognitiveService.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}