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

resource "azurerm_api_management_backend" "backend" {
  name                = var.backendName
  resource_group_name = var.resourceGroupName
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = var.backendUrl
}

resource "azurerm_api_management_api" "api" {
  name                = replace(lower(var.apiName)," ","-")
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


resource "azurerm_api_management_policy_fragment" "api_policy_fragments" {
  count             = length(var.policyFragments)
  api_management_id = azurerm_api_management.apim.id
  name              = var.policyFragments[count.index].name
  format            = "rawxml"
  value             = var.policyFragments[count.index].fragmentContent
}

resource "azurerm_api_management_api_policy" "base_policy" {
  api_name            = replace(lower(var.apiName)," ","-")
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
  xml_content = var.basePolicyContent
  depends_on = [ azurerm_api_management_api.api ]
}

resource "azurerm_api_management_api_operation_policy" "operation_policy" {
  count = length(var.operationPolicies)
  api_name            = replace(lower(var.apiName)," ","-")
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resourceGroupName
  operation_id = var.operationPolicies[count.index].operationId
  xml_content = var.operationPolicies[count.index].policyContent
  depends_on = [ azurerm_api_management_api.api, azurerm_api_management_policy_fragment.api_policy_fragments ]
}

resource "azurerm_api_management_named_value" "name_values" {
  count = length(var.nameValues)
  name                = var.nameValues[count.index].name
  resource_group_name = var.resourceGroupName
  api_management_name = azurerm_api_management.apim.name
  display_name        = var.nameValues[count.index].name
  value               = var.nameValues[count.index].value
}
