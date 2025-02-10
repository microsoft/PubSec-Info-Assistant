resource "azurerm_cognitive_account" "docIntelligenceAccount" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "FormRecognizer"
  sku_name                      = var.sku["name"]
  custom_subdomain_name         = var.customSubDomainName
  public_network_access_enabled = false
  local_auth_enabled            = false
  tags                          = var.tags
  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "docintPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  custom_network_interface_name = "infoasstdocintelnic"

  private_service_connection {
    name                           = "cognitiveAccount"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cognitive_account.docIntelligenceAccount.id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
    
  }
}