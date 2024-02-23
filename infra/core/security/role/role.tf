resource "azurerm_role_assignment" "role" {
  # name               = "${var.subscriptionId}${var.resourceGroupId}${var.principalId}${var.roleDefinitionId}"
  scope              = var.scope
  role_definition_id = "/subscriptions/${var.subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${var.roleDefinitionId}"
  principal_id       = var.principalId
}