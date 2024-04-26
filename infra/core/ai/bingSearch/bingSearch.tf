locals {
  arm_file_path = "arm_templates/bing_search/bing.template.json"
}

# Create the Bing Search instance via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_resource_group_template_deployment" "bing_search" {
  count               = var.enableWebChat ? 1 : 0
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "name"                      = { value = "${var.name}" },
    "location"                  = { value = "Global" },
    "sku"                       = { value = "${var.sku}" },
    "tags"                      = { value = var.tags },
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "bingsearch-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
}

resource "azurerm_key_vault_secret" "bing_search_key" {
  name         = "BINGSEARCH-KEY"
  value        = var.enableWebChat ? jsondecode(azurerm_resource_group_template_deployment.bing_search[0].output_content).key1.value : ""
  key_vault_id = var.keyVaultId
  expiration_date = timeadd(timestamp(), "1440h")  # 60 days * 24 hours
}