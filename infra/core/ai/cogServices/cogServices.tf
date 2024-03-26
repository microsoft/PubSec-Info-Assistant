resource "azurerm_cognitive_account" "cognitiveService" {
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resourceGroupName
  kind                  = "CognitiveServices"
  sku_name              = var.sku["name"]
  tags                  = var.tags
  custom_subdomain_name = var.name
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "ENRICHMENT-KEY"
  value        = azurerm_cognitive_account.cognitiveService.primary_access_key
  key_vault_id = var.keyVaultId
}

resource "azurerm_private_endpoint" "accountPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnetResourceId
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



