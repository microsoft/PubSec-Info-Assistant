resource "azurerm_cognitive_account" "cognitiveService" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "CognitiveServices"
  sku_name                      = var.sku["name"]
  tags                          = var.tags
  custom_subdomain_name         = var.name
  public_network_access_enabled = var.is_secure_mode ? false : true
}

module "cog_service_key" {
  source                        = "../../security/keyvaultSecret"
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  key_vault_name                = var.key_vault_name
  resourceGroupName             = var.resourceGroupName
  secret_name                   = "AZURE-AI-KEY"
  secret_value                  = azurerm_cognitive_account.cognitiveService.primary_access_key
  alias                         = "aisvckey"
  tags                          = var.tags
  kv_secret_expiration          = var.kv_secret_expiration
  contentType                   = "application/vnd.bag-StrongEncPasswordString"
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "accountPrivateEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
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