output "formRecognizerAccountName" {
  value = azurerm_cognitive_account.formRecognizerAccount.name
}

output "formRecognizerAccountEndpoint" {
  value = azurerm_cognitive_account.formRecognizerAccount.endpoint
}

output "formRecognizerAccount" {
  value = azurerm_cognitive_account.formRecognizerAccount.id
}

output "formPrivateEndpoint" {
  value = var.is_secure_mode ? azurerm_private_endpoint.formPrivateEndpoint[0].id : null
}