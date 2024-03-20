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

output "snetAzureMonitor_id" {
  value = azurerm_subnet.azureMonitor.id
}

output "snetApiManagement_id" {
  value = azurerm_subnet.apiManagement.id
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

output "snetAppInbound_id" {
  value = azurerm_subnet.appInbound.id
}

output "snetAppOutbound_id" {
  value = azurerm_subnet.appOutbound.id
}

output "snetFunctionInbound_id" {
  value = azurerm_subnet.functionInbound.id
}

output "snetFunctionOutbound_id" {
  value = azurerm_subnet.functionOutbound.id
}

output "snetEnrichmentInbound_id" {
  value = azurerm_subnet.enrichmentInbound.id
}

output "snetEnrichmentOutbound_id" {
  value = azurerm_subnet.enrichmentOutbound.id
}

