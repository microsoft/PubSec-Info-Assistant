resource "azurerm_cognitive_account" "formRecognizerAccount" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "FormRecognizer"
  sku_name                      = var.sku["name"]
  custom_subdomain_name         = var.customSubDomainName
  public_network_access_enabled = var.is_secure_mode ? false : true
  tags                          = var.tags
}

resource "azurerm_key_vault_secret" "docIntelligenceKey" {
  name         = "AZURE-FORM-RECOGNIZER-KEY"
  value        = azurerm_cognitive_account.formRecognizerAccount.primary_access_key
  key_vault_id = var.keyVaultId
}


resource "azurerm_private_endpoint" "formPrivateEndpoint" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resourceGroupName
  subnet_id           = var.subnetResourceId

  private_service_connection {
    name                           = "cognitiveAccount"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cognitive_account.formRecognizerAccount.id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
    
  }
}
