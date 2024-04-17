output "nsg_name" {
  value = azurerm_network_security_group.nsg.name  
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "snetAmpls_id" {
  value = azurerm_subnet.ampls.id
}

output "snetStorageAccount_id" {
  value = azurerm_subnet.storageAccount.id
}

output "snetCosmosDb_id" {
  value = azurerm_subnet.cosmosDb.id
}

output "snetAzureAi_id" {
  value = azurerm_subnet.azureAi.id
}

output "snetKeyVault_id" {
  value = azurerm_subnet.keyVault.id
}

output "snetApp_id" {
  value = azurerm_subnet.app.id
}

output "snetFunction_id" {
  value = azurerm_subnet.function.id
}

output "snetEnrichment_id" {
  value = azurerm_subnet.enrichment.id
}

output "snetIntegration_id" {
  value = azurerm_subnet.integration.id
}

output "snetSearch_id" {
  value = azurerm_subnet.aiSearch.id
}

output "snetAzureVideoIndexer_id" {
  value = azurerm_subnet.videoIndexer.id
}

output "snetBingSearch_id" {
  value = azurerm_subnet.bingSearch.id
}

output "snetAzureOpenAI_id" {
  value = azurerm_subnet.azureOpenAI.id
}