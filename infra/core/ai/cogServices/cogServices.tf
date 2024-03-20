resource "azurerm_cognitive_account" "cognitiveService" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resourceGroupName
  kind                     = "CognitiveServices"
  sku_name                 = var.sku["name"]
  tags                     = var.tags
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "ENRICHMENT-KEY"
  value        = azurerm_cognitive_account.cognitiveService.primary_access_key
  key_vault_id = var.keyVaultId
}



