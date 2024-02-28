output "account_id" {
  value = jsondecode(azurerm_resource_group_template_deployment.vi.output_content).avam_id.value
}

output "media_storage_account_name" {
  value = azurerm_storage_account.media_storage.name
}

output "media_storage_account_id" {
  value = azurerm_storage_account.media_storage.id
}

output "vi_name" {
  value = "infoasst-avi-${var.random_string}"
}

output "vi_id" {
  value = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.VideoIndexer/accounts/infoasst-avi-${var.random_string}"
}