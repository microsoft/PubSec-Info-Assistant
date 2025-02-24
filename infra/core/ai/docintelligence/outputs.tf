output "formRecognizerAccountName" {
  value = azurerm_cognitive_account.docIntelligenceAccount.name
}

output "formRecognizerAccountEndpoint" {
  value = azurerm_cognitive_account.docIntelligenceAccount.endpoint
}

output "formRecognizerAccount" {
  value = azurerm_cognitive_account.docIntelligenceAccount.id
}

output "formPrivateEndpoint" {
  value = azurerm_private_endpoint.docintPrivateEndpoint.id
}

output "docIntelligenceIdentity" {
  value = azurerm_cognitive_account.docIntelligenceAccount.identity[0].principal_id
}