output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "function_app_identity_principal_id" {
  value = azurerm_linux_function_app.function_app.identity.0.principal_id
}


# output "id" {
#   value = azurerm_service_plan.funcServicePlan.id
# }

output "name" {
  value = azurerm_service_plan.funcServicePlan.name
}

output "subnet_integration_id" {  
  value = var.subnetIntegration_id  
} 