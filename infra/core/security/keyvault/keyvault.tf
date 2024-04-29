data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resourceGroupName // Replace with your resource group name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  tags                        = var.tags
  enabled_for_template_deployment = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.kvAccessObjectId
    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", 
      "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",  
      "Verify", "WrapKey"
    ] 
  secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }

/*     network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices" 
    ip_rules                   = ["203.0.113.0/24", "198.51.100.0/24"]
    // Add the IDs of the subnets here if we want to allow traffic from specific subnets
    // virtual_network_subnet_ids = ["<subnet-id-1>", "<subnet-id-2>", ...]
  } */
}

resource "azurerm_key_vault_secret" "spClientKeySecret" {
  name         = "AZURE-CLIENT-SECRET"
  value        = var.spClientSecret
  key_vault_id = azurerm_key_vault.kv.id
}


