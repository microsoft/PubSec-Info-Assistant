output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "name" {
  value = azurerm_service_plan.funcServicePlan.name
}

output "subnet_integration_id" {  
  value = var.subnetIntegration_id  
} 

output "identityPrincipalId" {
  value = azurerm_linux_function_app.function_app.identity.0.principal_id
}

output "STORAGE_CONNECTION_STRING__queueServiceUri" {
  value = "https://${var.blobStorageAccountName}.queue.${var.endpointSuffix}"
}

output "STORAGE_CONNECTION_STRING__blobServiceUri" {
  value = "https://${var.blobStorageAccountName}.blob.${var.endpointSuffix}"
}