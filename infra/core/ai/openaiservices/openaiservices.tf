resource "azurerm_cognitive_account" "account" {
  count                           = var.useExistingAOAIService ? 0 : 1
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resourceGroupName
  kind                            = var.kind
  sku_name                        = var.sku["name"]
  public_network_access_enabled   = var.publicNetworkAccess == "Enabled" ? true : false
  tags = var.tags
}

resource "azurerm_cognitive_deployment" "deployment" {
  count                 = var.useExistingAOAIService ? 0 : length(var.deployments)
  name                  = var.deployments[count.index].name
  cognitive_account_id  = azurerm_cognitive_account.account[0].id
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

resource "azurerm_key_vault_secret" "openaiServiceKeySecret" {
  name         = "AZURE-OPENAI-SERVICE-KEY"
  value        = var.useExistingAOAIService ? var.openaiServiceKey : azurerm_cognitive_account.account[0].primary_access_key
  key_vault_id = var.keyVaultId
}

output "name" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].name
}

output "endpoint" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].endpoint
}
