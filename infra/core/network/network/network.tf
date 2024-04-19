//Create the Network Security Group

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  tags                = var.tags
}

//Create the DDoS plan

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.ddos_enabled ? 1 : 0
  name                = var.ddos_name
  resource_group_name = var.resourceGroupName
  location            = var.location
} 

//Create the Virtual Network

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = [var.vnetIpAddressCIDR]
  tags = var.tags

   ddos_protection_plan {
     id     = var.ddos_plan_id != "" ? var.ddos_plan_id : azurerm_network_ddos_protection_plan.ddos[0].id 
     enable = var.ddos_enabled
    } 
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

resource "azurerm_subnet" "app" {
  name                 = "app"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetAppCIDR]
}

resource "azurerm_subnet_network_security_group_association" "app_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "function" {
  name                 = "function"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetFunctionCIDR]
}

resource "azurerm_subnet_network_security_group_association" "function_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.function.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "enrichment" {
  name                 = "enrichment"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetEnrichmentCIDR]
}

resource "azurerm_subnet_network_security_group_association" "enrichment_snet_to_nsg" {
  subnet_id                 = azurerm_subnet.enrichment.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "integration" { 
  name                 = "integration"
  resource_group_name  = var.resourceGroupName
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.snetIntegrationCIDR]

  delegation {
    name = "integrationDelegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
    }
  }
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