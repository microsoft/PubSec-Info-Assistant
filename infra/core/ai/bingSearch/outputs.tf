output "id" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).id.value : ""
}

output "endpoint" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).endpoint.value : ""
}

output "key" {
  value = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).key1.value : ""
}