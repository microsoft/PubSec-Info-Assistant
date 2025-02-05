data "azurerm_client_config" "current" {}

locals {
  arm_file_path = "arm_templates/network_security_perimeter/nsp_assoc.template.json"
}

data "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.${var.azure_keyvault_domain}"
  resource_group_name = var.resourceGroupName
}

# Create the NSP Association via ARM Template
data "template_file" "workflow" {
  template = file(local.arm_file_path)
  vars = {
    arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  }
}

resource "azurerm_key_vault" "kv" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resourceGroupName // Replace with your resource group name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  tags                            = var.tags
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  public_network_access_enabled   = true //changed from false to true
  enable_rbac_authorization       = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [var.subnet_id]
    ip_rules                   = [var.deployment_machine_ip]
  }
}

resource "azurerm_key_vault_secret" "bing_api_key" {
  depends_on  = [
    azurerm_role_assignment.key_vault_rbac_infoasst
  ]
  name            = "BINGSEARCH-KEY"
  value           = var.bing_secret_value
  content_type    = "application/vnd.bag-StrongEncConnectionString"
  expiration_date = var.expiration_date
  key_vault_id    = azurerm_key_vault.kv.id
}

resource "azurerm_role_assignment" "key_vault_rbac_infoasst" {
  depends_on = [
    azurerm_key_vault.kv
  ]
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.kvAccessObjectId
}

//Create the Network Security Perimeter Association
resource "azurerm_resource_group_template_deployment" "nsp_assoc_w_kv" {
  count                         = var.useNetworkSecurityPerimeter ? 1 : 0
  resource_group_name           = var.resourceGroupName
  parameters_content            = jsonencode({
    "name"                      = { value = "${var.nsp_assoc_name}" },
    "nsp_name"                  = { value = "${var.nsp_name}" },
    "location"                  = { value = "${var.location}" },
    "tags"                      = { value = var.tags },
    "profileId"                 = { value = "${var.nsp_profile_id}" },
    "privateLinkResourceId"     = { value = azurerm_key_vault.kv.id },
  })
  template_content = data.template_file.workflow.template
  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name                          = "nsp-assoc-kv-${filemd5(local.arm_file_path)}"
  deployment_mode               = "Incremental"
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  custom_network_interface_name = "infoasstkvnic"

  private_service_connection {
    name                           = "${var.name}-kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv_dns_zone.id]
  }
}

 
 