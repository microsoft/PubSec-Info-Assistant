resource "azurerm_service_plan" "appServicePlan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName

  sku_name = "S1"
  os_type = "Linux"

  tags = var.tags
}

output "id" {
  value = azurerm_service_plan.appServicePlan.id
}

output "name" {
  value = azurerm_service_plan.appServicePlan.name
}
