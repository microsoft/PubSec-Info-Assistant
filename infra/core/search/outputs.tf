output "id" {
  value = azurerm_search_service.search.id
}

output "endpoint" {
  value = "https://${azurerm_search_service.search.name}.${var.azure_search_domain}/"
}

output "name" {
  value = azurerm_search_service.search.name
}