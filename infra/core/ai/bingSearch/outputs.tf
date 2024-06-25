output "id" {
  value = jsondecode(azurerm_resource_group_template_deployment.bing_search.output_content).id.value
}

output "endpoint" {
  value = jsondecode(azurerm_resource_group_template_deployment.bing_search.output_content).endpoint.value
}

output "key" {
  value = jsondecode(azurerm_resource_group_template_deployment.bing_search.output_content).key1.value
}