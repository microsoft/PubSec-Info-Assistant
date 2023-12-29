resource "azurerm_app_service_plan" "appServicePlan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  kind                = var.kind
  reserved            = var.reserved

  sku {
    tier = var.sku["tier"]
    size = var.sku["size"]
  }

  tags = var.tags
}

output "id" {
  value = azurerm_app_service_plan.appServicePlan.id
}

output "name" {
  value = azurerm_app_service_plan.appServicePlan.name
}
