
resource "azurerm_search_service" "search" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku                 = var.sku["name"]

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = true
  replica_count                 = 1
  partition_count               = 1
  semantic_search_sku           = var.semanticSearch //TODO Gov?
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "AZURE-SEARCH-SERVICE-KEY"
  value        = data.azurerm_search_service.search.primary_key
  key_vault_id = var.keyVaultId
}

output "id" {
  value = azurerm_search_service.search.id
}

output "endpoint" {
  value = var.isGovCloudDeployment ? "https://${azurerm_search_service.search.name}.search.azure.us/" : "https://${azurerm_search_service.search.name}.search.windows.net/"
}

output "name" {
  value = azurerm_search_service.search.name
}

data "azurerm_search_service" "search" {
  name                = azurerm_search_service.search.name
  resource_group_name = var.resourceGroupName
}
