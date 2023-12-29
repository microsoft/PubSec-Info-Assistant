
resource "azurerm_cognitive_account" "formRecognizerAccount" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resourceGroupName
  kind                     = "FormRecognizer"
  sku_name                 = var.sku["name"]
  custom_subdomain_name    = var.customSubDomainName
  public_network_access_enabled = var.publicNetworkAccess == "Enabled" ? true : false
  tags                     = var.tags
}


output "formRecognizerAccountName" {
  value = azurerm_cognitive_account.formRecognizerAccount.name
}

output "formRecognizerAccountEndpoint" {
  value = azurerm_cognitive_account.formRecognizerAccount.endpoint
}

output "formRecognizerAccountKey" {
  value = azurerm_cognitive_account.formRecognizerAccount.primary_access_key
}