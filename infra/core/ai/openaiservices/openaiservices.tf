resource "azurerm_cognitive_account" "openaiAccount" {
  name                                = var.existingAzureOpenAIServiceName != "" ? var.existingAzureOpenAIServiceName : var.name
  location                            = var.existingAzureOpenAILocation != "" ? var.existingAzureOpenAILocation : var.location
  resource_group_name                 = var.existingAzureOpenAIResourceGroup != "" ? var.existingAzureOpenAIResourceGroup : var.resourceGroupName
  kind                                = var.kind
  sku_name                            = var.sku["name"]
  public_network_access_enabled       = false
  local_auth_enabled                  = false
  outbound_network_access_restricted  = var.outbound_network_access_restricted
  custom_subdomain_name               = var.name
  tags = var.tags

  network_acls {
    default_action = "Allow"
    ip_rules       = var.network_acls_ip_rules

    dynamic "virtual_network_rules" {
      for_each = [1]
      content {
        subnet_id = var.subnet_id
      }
    }
  }
}

resource "azurerm_cognitive_deployment" "deployment" {
  count                 = length(var.deployments)
  name                  = var.deployments[count.index].name
  cognitive_account_id  = azurerm_cognitive_account.openaiAccount.id
  rai_policy_name       = var.deployments[count.index].rai_policy_name
  model {
    format              = "OpenAI"
    name                = var.deployments[count.index].model.name
    version             = var.deployments[count.index].model.version
  }
  sku {
    name                = var.deployments[count.index].sku.name
    capacity            = var.deployments[count.index].sku.capacity
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs" {
  name                       = azurerm_cognitive_account.openaiAccount.name
  target_resource_id         = azurerm_cognitive_account.openaiAccount.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId
  enabled_log  {
    category = "Audit"
  }
  enabled_log {
    category = "RequestResponse"
  }
  enabled_log {
    category = "Trace"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "openaiPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  custom_network_interface_name = "infoasstaoainic"

  private_service_connection {
    name                            = "cognitiveAccount"
    is_manual_connection            = false
    private_connection_resource_id  = azurerm_cognitive_account.openaiAccount.id
    subresource_names               = ["account"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids

  }
}