resource "azurerm_cognitive_account" "cognitiveService" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resourceGroupName
  kind                     = "CognitiveServices"
  sku_name                 = var.sku["name"]
  tags                     = var.tags
}


output "cognitiveServicerAccountName" {
  value = azurerm_cognitive_account.cognitiveService.name
}

output "cognitiveServiceID" {
  value = azurerm_cognitive_account.cognitiveService.id
}

output "cognitiveServiceEndpoint" {
  value = azurerm_cognitive_account.cognitiveService.endpoint
}

output "cognitiveServiceAccountKey" {
  value = azurerm_cognitive_account.cognitiveService.primary_access_key
}
