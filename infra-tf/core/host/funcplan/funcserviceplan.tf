resource "azurerm_service_plan" "funcServicePlan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku_name = "S2"
  os_type = "Linux"

  tags = var.tags
}

output "id" {
  value = azurerm_service_plan.funcServicePlan.id
}

output "name" {
  value = azurerm_service_plan.funcServicePlan.name
}
