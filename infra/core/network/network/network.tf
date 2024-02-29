resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = [var.vnetIpAddressCIDR]
  
  subnet {
    name           = "apiManagement"
    address_prefix = var.snetApiManagementCIDR
    
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "storageAccount"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "cosmosDb"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "azureAi"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "keyVault"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "appInbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "appOutbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "functionInbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "functionOutbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "enrichmentInbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  subnet {
    name           = "enrichmentOutbound"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
  tags = var.tags
}

resource "azurerm_subnet" "azureMonitor" {
  name                 = "azureMonitor"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureMonitorCIDR]
  
}

resource "azurerm_subnet" "apiManagement" {
  name                 = "apiManagement"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetApiManagementCIDR]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.EventHub",
    "Microsoft.ServiceBus",
    "Microsoft.Web"
  ]
}

resource "azurerm_subnet_network_security_group_association" "apiManagement_snet_to_nsg" {
  subnet_id = azurerm_subnet.apiManagement.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "storageAccount" {
  name                 = "storageAccount"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetStorageAccountCIDR]
}

resource "azurerm_subnet_network_security_group_association" "storageAccount_snet_to_nsg" {
  subnet_id = azurerm_subnet.storageAccount.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "cosmosDb" {
  name                 = "cosmosDb"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetCosmosDbCIDR]
}

resource "azurerm_subnet_network_security_group_association" "cosmosDb_snet_to_nsg" {
  subnet_id = azurerm_subnet.cosmosDb.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "azureAi" {
  name                 = "azureAi"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureAiCIDR]
}

resource "azurerm_subnet_network_security_group_association" "azureAi_snet_to_nsg" {
  subnet_id = azurerm_subnet.azureAi.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "keyVault" {
  name                 = "keyVault"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetKeyVaultCIDR]
}

resource "azurerm_subnet_network_security_group_association" "keyVault_snet_to_nsg" {
  subnet_id = azurerm_subnet.keyVault.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "appInbound" {
  name                 = "appInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAppInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "appInbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.appInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "appOutbound" {
  name                 = "appOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAppOutboundCIDR]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "appOutbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.appOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "functionInbound" {
  name                 = "functionInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetFunctionInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "functionInbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.functionInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "functionOutbound" {
  name                 = "functionOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetFunctionOutboundCIDR]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "functionOutbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.functionOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "enrichmentInbound" {
  name                 = "enrichmentInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetEnrichmentInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "enrichmentInbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.enrichmentInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "enrichmentOutbound" {
  name                 = "enrichmentOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetEnrichmentOutboundCIDR]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "enrichmentOutbound_snet_to_nsg" {
  subnet_id = azurerm_subnet.enrichmentOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}