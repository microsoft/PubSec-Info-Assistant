data "azurerm_client_config" "current" {}

resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
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

  network_acls {
    default_action             = "Deny"
    ip_rules                   = [var.userIpAddress]
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [var.kv_subnet]
  }
  
}

resource "azurerm_key_vault_secret" "spClientKeySecret" {
  name         = "AZURE-CLIENT-SECRET"
  value        = var.spClientSecret
  key_vault_id = azurerm_key_vault.kv.id
  expiration_date = timeadd(timestamp(), "1440h")  # 60 days * 24 hours
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "${var.name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resourceGroupName
  subnet_id           = var.kv_subnet

  private_service_connection {
    name                           = "${var.name}-kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
  }
}
