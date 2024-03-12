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

resource "azurerm_key_vault_secret" "docIntelligenceKey" {
  name         = "AZURE-FORM-RECOGNIZER-KEY"
  value        = azurerm_cognitive_account.formRecognizerAccount.primary_access_key
  key_vault_id = var.keyVaultId
}


output "formRecognizerAccountName" {
  value = azurerm_cognitive_account.formRecognizerAccount.name
}

output "formRecognizerAccountEndpoint" {
  value = azurerm_cognitive_account.formRecognizerAccount.endpoint
}
