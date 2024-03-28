output "id" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).id.value : null
}

output "endpoint" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).endpoint.value : null
}

output "key" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).key1.value : null
}