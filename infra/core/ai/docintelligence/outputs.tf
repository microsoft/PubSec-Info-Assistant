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
  value = var.is_secure_mode ? azurerm_private_endpoint.docintPrivateEndpoint[0].id : null
}

output "docIntelligenceIdentity" {
  value = azurerm_cognitive_account.docIntelligenceAccount.identity[0].principal_id
}