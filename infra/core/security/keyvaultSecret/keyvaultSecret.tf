locals {
  arm_file_path = "arm_templates/kv_secret/kv_secret.template.json"
}

# Create the Bing Search instance via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_resource_group_template_deployment" "kv_secret" {
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "keyVaultName"              = { value = "${var.key_vault_name}" },
    "secretName"                = { value = "${var.secret_name}" },
    "value"                    = { value = "${var.secret_value}" },
    "tags"                      = { value = var.tags },
    "expiration"                = { value = var.kv_secret_expiration },
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "kvs-${var.alias}-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
}