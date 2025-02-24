locals {
  arm_file_path = "arm_templates/network_security_perimeter/nsp.template.json"
}

# Create the Bing Search instance via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

//Create the Network Security Perimeter
resource "azurerm_resource_group_template_deployment" "nsp_w_profile" {
  resource_group_name = var.resourceGroupName
  parameters_content = jsonencode({
    "name"                      = { value = "${var.nsp_name}" },
    "location"                  = { value = "${var.location}" },
    "tags"                      = { value = var.tags },
    "profileName"               = { value = "${var.nsp_profile_name}" },
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "nsp-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
}