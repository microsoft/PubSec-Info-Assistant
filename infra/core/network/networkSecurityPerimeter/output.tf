output "id" {
  value = jsondecode(azurerm_resource_group_template_deployment.nsp_w_profile.output_content).id.value
}

output "profileId" {
  value = jsondecode(azurerm_resource_group_template_deployment.nsp_w_profile.output_content).profileId.value
}

output "nsp_name" {
  value = var.nsp_name
}