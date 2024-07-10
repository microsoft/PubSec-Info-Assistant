data "azurerm_client_config" "current" {}

data "azurerm_private_dns_zone" "kv_dns_zone" {
  count                = var.is_secure_mode ? 1 : 0
  name                = "privatelink.${var.azure_keyvault_domain}"
  resource_group_name = var.resourceGroupName
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
  public_network_access_enabled   = var.is_secure_mode ? false : true

  network_acls {
    default_action             = var.is_secure_mode ? "Deny" : "Allow" 
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.is_secure_mode ? [var.subnet_id] : []
  }
}
 
resource "azurerm_key_vault_access_policy" "infoasst" {
  depends_on  = [
    azurerm_key_vault.kv
  ]
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.kvAccessObjectId
 
  key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
      "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
      "Verify", "WrapKey"
    ]
 
  secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
  custom_network_interface_name = "infoasstkvnic"

  private_service_connection {
    name                           = "${var.name}-kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.kv_dns_zone[0].id]
  }
}