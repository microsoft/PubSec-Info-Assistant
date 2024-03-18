resource "azurerm_cognitive_account" "account" {
  count               = var.useExistingAOAIService ? 0 : 1
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  kind                = var.kind
  sku_name            = var.sku["name"]

  public_network_access_enabled      = var.public_network_access_enabled
  outbound_network_access_restricted = var.outbound_network_access_restricted
  custom_subdomain_name              = var.name

  network_acls {
    default_action = var.network_acls_default_action
    ip_rules       = var.network_acls_ip_rules


    virtual_network_rules {
      subnet_id = var.subnet_id
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "private_endpoint" {
  count               = var.useExistingAOAIService ? 0 : var.is_secure_mode ? 1 : 0
  name                = "private-endpoint-${azurerm_cognitive_account.account[0].name}"
  location            = var.location
  resource_group_name = var.resourceGroupName
  subnet_id           = var.subnetResourceId

  private_service_connection {
    name                           = "cognitiveAccount"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_private_endpoint.private_endpoint[count.index].id

  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}

resource "azurerm_cognitive_deployment" "deployment" {
  count                = var.useExistingAOAIService ? 0 : length(var.deployments)
  name                 = var.deployments[count.index].name
  cognitive_account_id = azurerm_cognitive_account.account[0].id
  rai_policy_name      = var.deployments[count.index].rai_policy_name
  model {
    format  = "OpenAI"
    name    = var.deployments[count.index].model.name
    version = var.deployments[count.index].model.version
  }
  scale {
    type     = "Standard"
    capacity = var.deployments[count.index].sku_capacity
  }
}

resource "azurerm_key_vault_secret" "openaiServiceKeySecret" {
  name         = "AZURE-OPENAI-SERVICE-KEY"
  value        = var.useExistingAOAIService ? var.openaiServiceKey : azurerm_cognitive_account.account[0].primary_access_key
  key_vault_id = var.keyVaultId
}
