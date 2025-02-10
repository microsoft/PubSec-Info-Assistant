locals {
  allowed_ip_cidr = [for ip in var.deployment_public_ip : "${ip}/32"]
}

resource "azurerm_search_service" "search" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  sku                           = var.sku
  tags                          = var.tags
  public_network_access_enabled = true
  local_authentication_enabled  = false
  replica_count                 = var.replica_count
  partition_count               = 1
  semantic_search_sku           = var.semanticSearch 

  allowed_ips = local.allowed_ip_cidr
  
  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "searchPrivateEndpoint" {
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet.id
  custom_network_interface_name = "infoasstsearchnic"

  private_service_connection {
    name                           = "${var.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  depends_on = [ azurerm_search_shared_private_link_service.searchToAIServicesPrivateLinkService, azurerm_search_shared_private_link_service.searchTostoragePrivateLinkService]
}

resource "azurerm_search_shared_private_link_service" "searchTostoragePrivateLinkService" {
  name                  = "${var.name}-to-storage-private-link-service"
  search_service_id     = azurerm_search_service.search.id
  subresource_name      = "blob"
  target_resource_id    = var.storage_account_id
  request_message       = "Connection from Search Service to Storage Account setup by Terraform"
}

resource "null_resource" "searchToStoragePrivateLinkService" {
  depends_on = [ azurerm_search_service.search, azurerm_search_shared_private_link_service.searchTostoragePrivateLinkService]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      privateEndpointId=$(az network private-endpoint-connection list --resource-group ${var.resourceGroupName} --type Microsoft.Storage/storageAccounts --name ${var.storage_account_name} --query "[?contains(properties.privateEndpoint.id, '${var.name}-to-storage-private-link-service')].id" --out tsv)
      az network private-endpoint-connection approve --id $privateEndpointId --description "Approved in Terraform"
    EOT
  }
  triggers = {
    blob_private_endpoint_id = azurerm_search_shared_private_link_service.searchTostoragePrivateLinkService.id
  }
}

resource "azurerm_search_shared_private_link_service" "searchToAIServicesPrivateLinkService" {
  name                  = "${var.name}-to-aiservices-private-link-service"
  search_service_id     = azurerm_search_service.search.id
  subresource_name      = "cognitiveservices_account"
  target_resource_id    = var.cognitive_services_account_id
  request_message       = "Connection from Search Service to AI Services setup by Terraform"

  depends_on = [ azurerm_search_shared_private_link_service.searchTostoragePrivateLinkService ]
}


resource "null_resource" "searchToAIServicesPrivateLinkService" {
  depends_on = [ azurerm_search_service.search, azurerm_search_shared_private_link_service.searchToAIServicesPrivateLinkService]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      privateEndpointId=$(az network private-endpoint-connection list --resource-group ${var.resourceGroupName} --type Microsoft.CognitiveServices/accounts --name ${var.cognitive_services_account_name} --query "[?contains(properties.privateEndpoint.id, '${var.name}-to-aiservices-private-link-service')].id" --out tsv)
      az network private-endpoint-connection approve --id $privateEndpointId --description "Approved in Terraform"
    EOT
  }
  triggers = {
    cognitive_services_account_private_endpoint_id = azurerm_search_shared_private_link_service.searchToAIServicesPrivateLinkService.id
  }
}