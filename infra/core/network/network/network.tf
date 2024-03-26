//Create the Network Security Group

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

//Create the Virtual Network

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = [var.vnetIpAddressCIDR]
  tags = var.tags
}

resource "azurerm_subnet" "ampls" {
  name                 = "ampls"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureMonitorCIDR]
  private_endpoint_network_policies_enabled = true
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_network_security_group_association" "ampls_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.ampls.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "storageAccount" {
  name                 = "storageAccount"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetStorageAccountCIDR]
}

resource "azurerm_subnet_network_security_group_association" "storageAccount_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.storageAccount.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "cosmosDb" {
  name                 = "cosmosDb"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetCosmosDbCIDR]
}

resource "azurerm_subnet_network_security_group_association" "cosmosDb_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.cosmosDb.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "azureAi" {
  name                 = "azureAi"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureAiCIDR]
  service_endpoints    = ["Microsoft.CognitiveServices"]
}

resource "azurerm_subnet_network_security_group_association" "azureAi_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.azureAi.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "keyVault" {
  name                 = "keyVault"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetKeyVaultCIDR]
}

resource "azurerm_subnet_network_security_group_association" "keyVault_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.keyVault.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "appInbound" {
  name                 = "appInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAppInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "appInbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.appInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "appOutbound" {
  name                 = "appOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAppOutboundCIDR]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet_network_security_group_association" "appOutbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.appOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "functionInbound" {
  name                 = "functionInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetFunctionInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "functionInbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.functionInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "functionOutbound" {
  name                 = "functionOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetFunctionOutboundCIDR]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "functionOutbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.functionOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "enrichmentInbound" {
  name                 = "enrichmentInbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetEnrichmentInboundCIDR]
}

resource "azurerm_subnet_network_security_group_association" "enrichmentInbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.enrichmentInbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "enrichmentOutbound" {
  name                 = "enrichmentOutbound"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetEnrichmentOutboundCIDR]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "enrichmentOutbound_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.enrichmentOutbound.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "videoIndexer" {
  name                 = "videoIndexer"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureVideoIndexerCIDR]
}

resource "azurerm_subnet_network_security_group_association" "videoIndexer_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.videoIndexer.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "aiSearch" {
  name                 = "aiSearch"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetSearchServiceCIDR]
}

resource "azurerm_subnet_network_security_group_association" "aiSearch_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.aiSearch.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "bingSearch" {
  name                 = "bingSearch"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetBingServiceCIDR]
}

resource "azurerm_subnet_network_security_group_association" "bingSearch_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.bingSearch.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "azureOpenAI" {
  name                 = "azureOpenAI"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAzureOpenAICIDR]
  service_endpoints    = ["Microsoft.CognitiveServices"]
}

resource "azurerm_subnet_network_security_group_association" "azureOpenAI_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.azureOpenAI.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}