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

output "snetAmpls_name" {
  value = data.azurerm_subnet.ampls.name
}

output "snetStorage_name" {
  value = data.azurerm_subnet.storageAccount.name
}

output "snetStorage_id" {
  value = data.azurerm_subnet.storageAccount.id
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

output "snetKeyVault_name" {
  value = data.azurerm_subnet.keyVault.name
}

output "snetApp_id" {
  value = data.azurerm_subnet.app.id
}

output "snetApp_name" {
  value = data.azurerm_subnet.app.name
}

output "snetIntegration_id" {
  value = data.azurerm_subnet.integration.id
}

output "snetIntegration_name" {
  value = data.azurerm_subnet.integration.name
}

output "snetSearch_name" {
  value = data.azurerm_subnet.aiSearch.name
}

output "snetAzureOpenAI_id" {
  value = data.azurerm_subnet.azureOpenAI.id
}

output "snetAzureOpenAI_name" {
  value = data.azurerm_subnet.azureOpenAI.name
}

output "ddos_plan_id" {
  value = var.useDDOSProtectionPlan ? var.ddos_plan_id == "" ? azurerm_network_ddos_protection_plan.ddos[0].id : var.ddos_plan_id : ""
}

output "dns_private_resolver_ip" {
  value = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver.ip_configurations[0].private_ip_address
}