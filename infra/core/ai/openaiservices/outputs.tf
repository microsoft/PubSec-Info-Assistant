output "name" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].name
}

output "endpoint" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].endpoint
}

output "id" {
  value = var.useExistingAOAIService ? "" : azurerm_cognitive_account.account[0].id
}