output "nsg_name" {
  value = azurerm_network_security_group.nsg.name  
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}

output "vnet_name" {
  value = var.vnet_name
}

output "vnet_id" {
  value = jsondecode(azurerm_resource_group_template_deployment.vnet_w_subnets.output_content).id.value
}

output "snetAmpls_id" {
  value = data.azurerm_subnet.ampls.id
}

output "snetStorage_id" {
  value = data.azurerm_subnet.storageAccount.id
}

output "snetStorage_name" {
  value = data.azurerm_subnet.storageAccount.name
}

output "snetCosmosDb_id" {
  value = data.azurerm_subnet.cosmosDb.id
}

output "snetAzureAi_id" {
  value = data.azurerm_subnet.azureAi.id
}

output "snetAzureAi_name" {
  value = data.azurerm_subnet.azureAi.name
}

output "snetKeyVault_id" {
  description = "The ID of the subnet dedicated for the Key Vault"
  value = data.azurerm_subnet.keyVault.id
}

output "snetACR_id" {
  value = data.azurerm_subnet.acr.id
}

output "snetApp_id" {
  value = data.azurerm_subnet.app.id
}

output "snetFunction_id" {
  value = data.azurerm_subnet.function.id
}

output "snetEnrichment_id" {
  value = data.azurerm_subnet.enrichment.id
}

output "snetIntegration_id" {
  value = data.azurerm_subnet.integration.id
}

output "snetSearch_id" {
  value = data.azurerm_subnet.aiSearch.id
}

output "snetAzureOpenAI_id" {
  value = data.azurerm_subnet.azureOpenAI.id
}

output "ddos_plan_id" {
  value = var.ddos_plan_id == "" ? azurerm_network_ddos_protection_plan.ddos[0].id : var.ddos_plan_id
}