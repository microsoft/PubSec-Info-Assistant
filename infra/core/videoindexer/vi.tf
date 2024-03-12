locals {
  arm_file_path = "arm_templates/video_indexer/avi.template.json"
}

# Create a media services instance
resource "azurerm_storage_account" "media_storage" {
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  name                            = "infoasststoremedia${var.random_string}"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
}

# Create the VI instance via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_user_assigned_identity" "vi" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "infoasst-ua-ident-${var.random_string}"
}

resource "azurerm_role_assignment" "vi_storageaccount_mi_access" {
  scope                = azurerm_storage_account.media_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vi.principal_id
}

resource "azurerm_resource_group_template_deployment" "vi" {
  depends_on          = [azurerm_role_assignment.vi_storageaccount_mi_access]
  resource_group_name = var.resource_group_name
  parameters_content = jsonencode({
    "name"                      = { value = "infoasst-avi-${var.random_string}" },
    "managedIdentityId"         = { value = azurerm_user_assigned_identity.vi.id },
    "storageServicesResourceId" = { value = azurerm_storage_account.media_storage.id },
    "tags"                      = { value = var.tags },
    "apiVersion"                = { value = var.video_indexer_api_version }
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "avi-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
}

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