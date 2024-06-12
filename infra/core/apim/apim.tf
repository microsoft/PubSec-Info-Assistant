locals {
  subscription_key_file_name="subscriptionkey.txt"
}
resource "azurerm_api_management" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resourceGroupName
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  sku_name            = "${var.sku}_${var.sku_count}"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_product" "unlimited" {
  product_id            = "unlimited"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resourceGroupName
  display_name          = "Unlimited"
  subscription_required = true
  approval_required     = true
  subscriptions_limit   = 1
  published             = true
}

resource "azurerm_api_management_product_group" "unlimited_developers_group" {
  product_id          = azurerm_api_management_product.unlimited.product_id
  group_name          = "developers"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
}

resource "azurerm_api_management_product_group" "unlimited_guests_group" {
  product_id          = azurerm_api_management_product.unlimited.product_id
  group_name          = "guests"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
}

resource "azurerm_api_management_backend" "backend" {
  name                = var.backendName
  resource_group_name = var.resourceGroupName
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = var.backendUrl
}

resource "azurerm_api_management_api" "api" {
  name                = replace(lower(var.apiName), " ", "-")
  resource_group_name = var.resourceGroupName
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = var.apiName
  path                = ""
  protocols           = ["https"]

  import {
    content_format = "openapi+json"
    content_value  = var.apiContent
  }
}

resource "azurerm_api_management_product_api" "unlimited_api" {
  api_name            = azurerm_api_management_api.api.name
  product_id          = azurerm_api_management_product.unlimited.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
}

resource "azurerm_api_management_policy_fragment" "api_policy_fragments" {
  count             = length(var.policyFragments)
  api_management_id = azurerm_api_management.apim.id
  name              = var.policyFragments[count.index].name
  format            = "rawxml"
  value             = var.policyFragments[count.index].fragmentContent
}

resource "azurerm_api_management_api_policy" "base_policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
  xml_content         = var.basePolicyContent
  depends_on          = [azurerm_api_management_api.api]
}

resource "azurerm_api_management_api_operation_policy" "operation_policy" {
  count               = length(var.operationPolicies)
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
  operation_id        = var.operationPolicies[count.index].operationId
  xml_content         = var.operationPolicies[count.index].policyContent
  depends_on          = [azurerm_api_management_api.api, azurerm_api_management_policy_fragment.api_policy_fragments]
}

resource "azurerm_api_management_named_value" "name_values" {
  count               = length(var.nameValues)
  name                = var.nameValues[count.index].name
  resource_group_name = var.resourceGroupName
  api_management_name = azurerm_api_management.apim.name
  display_name        = var.nameValues[count.index].name
  value               = var.nameValues[count.index].value
}


resource "null_resource" "get_subscription_key" {
  depends_on = [azurerm_api_management_product.unlimited]
  provisioner "local-exec" {
   
    command  = <<EOT
    $subscriptonId=az rest --uri "${azurerm_api_management.apim.id}/subscriptions?api-version=2022-08-01" --query "value[? contains(properties.scope,'${azurerm_api_management_product.unlimited.product_id}')] | [0].name" -o tsv
    az rest --method post --uri "${azurerm_api_management.apim.id}/subscriptions/$subscriptonId/listSecrets?api-version=2022-08-01" --query primaryKey -o tsv > ${local.subscription_key_file_name}
  EOT
  interpreter = ["pwsh", "-Command"]
  }
}

data "local_file" "subscription_key" {
  filename = local.subscription_key_file_name
  depends_on = [null_resource.get_subscription_key]
}