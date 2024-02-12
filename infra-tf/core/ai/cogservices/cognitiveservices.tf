resource "azurerm_cognitive_account" "account" {
  count = var.useExistingAOAIService ? 0 : 1
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  kind                = var.kind
  sku_name            = var.sku["name"]
  custom_subdomain_name    = var.customSubDomainName
  public_network_access_enabled = var.publicNetworkAccess == "Enabled" ? true : false
  tags = var.tags
}


resource "azurerm_cognitive_deployment" "deployment" {
  count = var.useExistingAOAIService ? 0 : length(var.deployments)

  name                 = var.deployments[count.index].name
  cognitive_account_id = azurerm_cognitive_account.account[0].id

  model {
    format  = "OpenAI"
    name    = var.deployments[count.index].model.name
    version = var.deployments[count.index].model.version
  }

  scale {
    type = "Standard"
  }
}

resource "azurerm_key_vault_secret" "openaiServiceKeySecret" {
  name         = "AZURE-OPENAI-SERVICE-KEY"
  value        = var.useExistingAOAIService ? var.openaiServiceKey : azurerm_cognitive_account.account[0].primary_access_key
  key_vault_id = var.keyVaultId
}


output "endpoint" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].endpoint
}

output "id" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].id
}

output "name" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].name
}
