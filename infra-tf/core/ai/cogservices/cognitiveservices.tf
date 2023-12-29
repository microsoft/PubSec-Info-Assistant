resource "azurerm_cognitive_account" "account" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  kind                = var.kind
  sku_name            = var.sku["name"]
  custom_subdomain_name    = var.customSubDomainName
  public_network_access_enabled = var.publicNetworkAccess == "Enabled" ? true : false
  tags = var.tags
}

# resource "azurerm_cognitive_account_deployment" "deployment" {
#   count = length(var.deployments)

#   name                = var.deployments[count.index]["name"]
#   resource_group_name = var.resourceGroupName
#   account_name        = azurerm_cognitive_account.account.name

#   model = var.deployments[count.index]["model"]

#   sku_name = lookup(var.deployments[count.index], "sku", false) ? var.deployments[count.index]["sku"]["name"] : "Standard"
#   sku_capacity = lookup(var.deployments[count.index], "sku", false) ? var.deployments[count.index]["sku"]["capacity"] : 20

#   rai_policy_name = lookup(var.deployments[count.index], "raiPolicyName", null)
# }


output "endpoint" {
  value = azurerm_cognitive_account.account.endpoint
}

output "id" {
  value = azurerm_cognitive_account.account.id
}

output "name" {
  value = azurerm_cognitive_account.account.name
}

output "key" {
  value = azurerm_cognitive_account.account.primary_access_key
}
