resource "azurerm_cognitive_account" "formRecognizerAccount" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  kind                          = "FormRecognizer"
  sku_name                      = var.sku["name"]
  custom_subdomain_name         = var.customSubDomainName
  public_network_access_enabled = var.is_secure_mode ? false : true
  local_auth_enabled            = var.is_secure_mode ? false : true
  tags                          = var.tags
}

module "docIntelligenceKey" {
  source                        = "../../security/keyvaultSecret"
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  resourceGroupName             = var.resourceGroupName
  key_vault_name                = var.key_vault_name
  secret_name                   = "AZURE-FORM-RECOGNIZER-KEY"
  secret_value                  = azurerm_cognitive_account.formRecognizerAccount.primary_access_key
  alias                         = "docintkey"
  tags                          = var.tags
  kv_secret_expiration          = var.kv_secret_expiration
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "formPrivateEndpoint" {
  count               = var.is_secure_mode ? 1 : 0
  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resourceGroupName
  subnet_id           = data.azurerm_subnet.subnet[0].id

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