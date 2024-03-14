
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
  semantic_search_sku           = var.semanticSearch
}

resource "azurerm_key_vault_secret" "search_service_key" {
  name         = "AZURE-SEARCH-SERVICE-KEY"
  value        = data.azurerm_search_service.search.primary_key
  key_vault_id = var.keyVaultId
}


data "azurerm_search_service" "search" {
  name                = azurerm_search_service.search.name
  resource_group_name = var.resourceGroupName
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "'${var.name}-network-interface'"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false

  }
}

resource "azurerm_private_dns_zone" "searchServiceDnsZone" {
  name                = "${var.name}-private-dns-zone-group"
  resource_group_name = var.resourceGroupName

}

