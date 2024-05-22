resource "azurerm_cognitive_account" "openaiAccount" {
  count                               = var.useExistingAOAIService ? 0 : 1
  name                                = var.name
  location                            = var.location
  resource_group_name                 = var.resourceGroupName
  kind                                = var.kind
  sku_name                            = var.sku["name"]
  public_network_access_enabled       = var.is_secure_mode ? false : true
  outbound_network_access_restricted  = var.outbound_network_access_restricted
  custom_subdomain_name               = var.name
  tags = var.tags

  network_acls {
    default_action = "Allow"
    ip_rules       = var.network_acls_ip_rules


    virtual_network_rules {
      subnet_id = var.subnetResourceId
    }
  }
}

resource "azurerm_cognitive_deployment" "deployment" {
  count                 = var.useExistingAOAIService ? 0 : length(var.deployments)
  name                  = var.deployments[count.index].name
  cognitive_account_id  = azurerm_cognitive_account.openaiAccount[0].id
  rai_policy_name       = var.deployments[count.index].rai_policy_name
  model {
    format              = "OpenAI"
    name                = var.deployments[count.index].model.name
    version             = var.deployments[count.index].model.version
  }
  scale {
    type                = "Standard"
    capacity            = var.deployments[count.index].sku_capacity
  }
}

resource "azurerm_private_endpoint" "openaiPrivateEndpoint" {
  count               = var.useExistingAOAIService ? 0 : var.is_secure_mode ? 1 : 0
  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resourceGroupName
  subnet_id           = var.subnetResourceId

  private_service_connection {
    name                            = "cognitiveAccount"
    is_manual_connection            = false
    private_connection_resource_id  = azurerm_cognitive_account.openaiAccount[count.index].id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}

module "openaiServiceKeySecret" {
  source                        = "../../security/keyvaultSecret"
  key_vault_name                = var.key_vault_name
  secret_name                   = "AZURE-OPENAI-SERVICE-KEY"
  secret_value                  = var.useExistingAOAIService ? var.openaiServiceKey : azurerm_cognitive_account.openaiAccount[0].primary_access_key
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  resourceGroupName             = var.resourceGroupName
  tags                          = var.tags
  alias                         = "openaikey"
  kv_secret_expiration          = var.kv_secret_expiration
}