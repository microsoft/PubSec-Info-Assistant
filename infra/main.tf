locals {
  tags            = { ProjectName = "Information Assistant", BuildNumber = var.buildNumber }
  azure_roles     = jsondecode(file("${path.module}/azure_roles.json"))
  selected_roles  = ["CognitiveServicesOpenAIUser", 
                      "CognitiveServicesUser", 
                      "StorageBlobDataOwner",
                      "StorageBlobDataContributor",
                      "StorageQueueDataContributor", 
                      "SearchServiceContributor",
                      "SearchIndexDataContributor"]

  deployment_public_ip_list = strcontains(var.deployment_public_ip, ",") ? split(",", var.deployment_public_ip) : [var.deployment_public_ip]
}


data "azurerm_client_config" "current" {}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

// Organize resources in a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName != "" ? var.resourceGroupName : "infoasst-${var.environmentName}"
  location = var.location
  tags     = merge(local.tags, { "azd-env-name" = "${var.environmentName}" })
}

module "entraObjects" {
  source                            = "./core/aad"
  useCustomEntra                    = var.useCustomEntra
  requireWebsiteSecurityMembership  = var.requireWebsiteSecurityMembership
  randomString                      = random_string.random.result
  azure_websites_domain             = var.azure_websites_domain
  aadWebClientId                    = var.aadWebClientId
  aadMgmtClientId                   = var.aadMgmtClientId
  aadMgmtServicePrincipalId         = var.aadMgmtServicePrincipalId
  entraOwners                       = var.entraOwners
  serviceManagementReference        = var.serviceManagementReference
  password_lifetime                 = var.password_lifetime
}

// Create the Virtual Network, Subnets, and Network Security Group
module "network" {
  source                          = "./core/network/network"
  vnet_name                       = "infoasst-vnet-${random_string.random.result}"
  nsg_name                        = "infoasst-nsg-${random_string.random.result}"
  ddos_name                       = "infoasst-ddos-${random_string.random.result}"
  dns_resolver_name               = "infoasst-dns-${random_string.random.result}"
  useDDOSProtectionPlan           = var.useDDOSProtectionPlan
  ddos_plan_id                    = var.ddos_plan_id
  location                        = var.location
  tags                            = local.tags
  resourceGroupName               = azurerm_resource_group.rg.name
  vnetIpAddressCIDR               = var.virtual_network_CIDR
  snetAzureMonitorCIDR            = var.azure_monitor_CIDR
  snetStorageAccountCIDR          = var.storage_account_CIDR
  snetAzureAiCIDR                 = var.azure_ai_CIDR
  snetKeyVaultCIDR                = var.key_vault_CIDR
  snetAppCIDR                     = var.webapp_CIDR
  snetIntegrationCIDR             = var.integration_CIDR
  snetSearchServiceCIDR           = var.search_service_CIDR
  snetBingServiceCIDR             = var.bing_service_CIDR
  snetAzureOpenAICIDR             = var.azure_openAI_CIDR
  snetDnsCIDR                     = var.dns_CIDR
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  azure_environment               = var.azure_environment
}

// Create the network security perimeter
module "network_security_perimeter" {
  count                         = var.useNetworkSecurityPerimeter ? 1 : 0
  source                        = "./core/network/networkSecurityPerimeter"
  nsp_name                      = "infoasst-nsp-${random_string.random.result}"
  nsp_profile_name              = "infoasst-nsp-profile-${random_string.random.result}"
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  location                      = var.location
  resourceGroupName             = azurerm_resource_group.rg.name
  tags                          = local.tags
}

// Create the Private DNS Zones for all the services
module "privateDnsZoneAzureOpenAi" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.${var.azure_openai_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-azure-openai-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneAzureAi" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.${var.azure_ai_private_link_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-azure-ai-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneApp" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.${var.azure_websites_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-app-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneStorageAccountBlob" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.blob.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-blob-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}


module "privateDnsZoneStorageAccountFile" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.file.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-file-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneStorageAccountTable" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.table.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-table-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneStorageAccountQueue" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.queue.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-queue-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneKeyVault" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.${var.azure_keyvault_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-kv-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "privateDnsZoneSearchService" {
  source             = "./core/network/privateDNS"
  name               = "privatelink.${var.azure_search_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-search-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network.vnet_id
  tags               = local.tags
  depends_on = [ module.network ]
}

module "logging" {
  depends_on = [ module.network ]
  source = "./core/logging/loganalytics"
  logAnalyticsName        = var.logAnalyticsName != "" ? var.logAnalyticsName : "infoasst-la-${random_string.random.result}"
  applicationInsightsName = var.applicationInsightsName != "" ? var.applicationInsightsName : "infoasst-ai-${random_string.random.result}"
  location                = var.location
  tags                    = local.tags
  skuName                 = "PerGB2018"
  resourceGroupName       = azurerm_resource_group.rg.name
  privateLinkScopeName                  = "infoasst-ampls-${random_string.random.result}"
  privateDnsZoneNameMonitor             = "privatelink.${var.azure_monitor_domain}"
  privateDnsZoneNameOms                 = "privatelink.${var.azure_monitor_oms_domain}"
  privateDnSZoneNameOds                 = "privatelink.${var.azure_monitor_ods_domain}"
  privateDnsZoneNameAutomation          = "privatelink.${var.azure_automation_domain}"
  privateDnsZoneResourceIdBlob          = module.privateDnsZoneStorageAccountBlob.privateDnsZoneResourceId
  privateDnsZoneNameBlob                = module.privateDnsZoneStorageAccountBlob.privateDnsZoneName
  groupId                               = "azuremonitor"
  subnet_name                           = module.network.snetAmpls_name
  vnet_name                             = module.network.vnet_name
  ampls_subnet_CIDR                     = var.azure_monitor_CIDR
  vnet_id                               = module.network.vnet_id
  nsg_id                                = module.network.nsg_id
  nsg_name                              = module.network.nsg_name
}

module "storage" {
  source                          = "./core/storage"
  name                            = var.storageAccountName != "" ? var.storageAccountName : "infoasststore${random_string.random.result}"
  location                        = var.location
  tags                            = local.tags
  accessTier                      = "Hot"
  allowBlobPublicAccess           = false
  resourceGroupName               = azurerm_resource_group.rg.name
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  deleteRetentionPolicy = {
    days                          = 7
  }
  containers                      = ["content","website","upload","logs","config"]
  tables                          = ["enrichmentstatus",  "fileprocessingstatus"]
  subnet_name                     = module.network.snetStorage_name
  vnet_name                       = module.network.vnet_name
  private_dns_zone_ids            = [module.privateDnsZoneStorageAccountBlob.privateDnsZoneResourceId,
                                       module.privateDnsZoneStorageAccountFile.privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountTable.privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountQueue.privateDnsZoneResourceId]
  network_rules_allowed_subnets   = [module.network.snetIntegration_id, module.network.snetStorage_id]
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId
  useNetworkSecurityPerimeter   = var.useNetworkSecurityPerimeter
  nsp_name                      = var.useNetworkSecurityPerimeter ? module.network_security_perimeter[0].nsp_name : ""
  nsp_profile_id                = var.useNetworkSecurityPerimeter ? module.network_security_perimeter[0].profileId : ""
  nsp_assoc_name                = "infoasst-nsp-assoc-storage-${random_string.random.result}"
  deployment_machine_ip         = local.deployment_public_ip_list
}

module "kvModule" {
  source                        = "./core/security/keyvault" 
  name                          = "infoasst-kv-${random_string.random.result}"
  location                      = var.location
  kvAccessObjectId              = data.azurerm_client_config.current.object_id
  resourceGroupName             = azurerm_resource_group.rg.name
  tags                          = local.tags
  subnet_name                   = module.network.snetKeyVault_name
  vnet_name                     = module.network.vnet_name
  subnet_id                     = module.network.snetKeyVault_id
  private_dns_zone_ids          = [module.privateDnsZoneApp.privateDnsZoneResourceId]
  depends_on                    = [ module.entraObjects, module.privateDnsZoneKeyVault ]
  azure_keyvault_domain         = var.azure_keyvault_domain
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  deployment_machine_ip         = local.deployment_public_ip_list
  bing_secret_value             = var.useWebChat ? module.bingSearch[0].key : ""
  expiration_date               = var.kv_secret_expiration
  useNetworkSecurityPerimeter   = var.useNetworkSecurityPerimeter
  nsp_name                      = var.useNetworkSecurityPerimeter ? module.network_security_perimeter[0].nsp_name : ""
  nsp_profile_id                = var.useNetworkSecurityPerimeter ? module.network_security_perimeter[0].profileId : ""
  nsp_assoc_name                = "infoasst-nsp-assoc-kv-${random_string.random.result}"
}

# // The application frontend
module "webapp" {
  source                              = "./core/host/webapp"
  name                                = var.backendServiceName != "" ? var.backendServiceName : "infoasst-web-${random_string.random.result}"
  plan_name                           = var.appServicePlanName != "" ? var.appServicePlanName : "infoasst-asp-${random_string.random.result}"
  sku = {
    size                              = var.appServiceSkuSize
    capacity                          = 3
  }
  kind                                = "linux"
  resourceGroupName                   = azurerm_resource_group.rg.name
  location                            = var.location
  tags                                = local.tags
  runtimeVersion                      = "3.12" 
  scmDoBuildDuringDeployment          = true
  managedIdentity                     = true
  alwaysOn                            = true
  appCommandLine                      = "gunicorn --workers 2 --worker-class uvicorn.workers.UvicornWorker app:app --timeout 600"
  healthCheckPath                     = "/health"
  logAnalyticsWorkspaceResourceId     = module.logging.logAnalyticsId
  azure_portal_domain                 = var.azure_portal_domain
  enableOryxBuild                     = true
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
  tenantId                            = data.azurerm_client_config.current.tenant_id
  subnet_name                         = module.network.snetApp_name
  vnet_name                           = module.network.vnet_name
  snetIntegration_id                  = module.network.snetIntegration_id
  private_dns_zone_ids                = [module.privateDnsZoneApp.privateDnsZoneResourceId]
  private_dns_zone_name               = module.privateDnsZoneApp.privateDnsZoneName
  scm_public_ip                       = local.deployment_public_ip_list
  randomString                        = random_string.random.result
  azure_environment                   = var.azure_environment
  keyVaultUri                         = module.kvModule.keyVaultUri
  azure_sts_issuer_domain             = var.azure_sts_issuer_domain

  appSettings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING   = module.logging.applicationInsightsConnectionString
    AZURE_BLOB_STORAGE_ACCOUNT              = module.storage.name
    AZURE_BLOB_STORAGE_ENDPOINT             = module.storage.primary_blob_endpoint
    AZURE_BLOB_STORAGE_CONTAINER            = var.contentContainerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER     = var.uploadContainerName
    AZURE_OPENAI_SERVICE                    = module.openaiServices.name
    AZURE_OPENAI_RESOURCE_GROUP             = azurerm_resource_group.rg.name
    AZURE_OPENAI_ENDPOINT                   = module.openaiServices.endpoint
    AZURE_OPENAI_AUTHORITY_HOST             = var.azure_openai_authority_host
    AZURE_ARM_MANAGEMENT_API                = var.azure_arm_management_api
    AZURE_SEARCH_INDEX                      = var.searchIndexName
    AZURE_SEARCH_SERVICE                    = module.searchServices.name
    AZURE_SEARCH_SERVICE_ENDPOINT           = module.searchServices.endpoint
    AZURE_SEARCH_AUDIENCE                   = var.azure_search_scope
    AZURE_OPENAI_CHATGPT_DEPLOYMENT         = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
    AZURE_OPENAI_CHATGPT_MODEL_NAME         = var.chatGptModelName
    AZURE_OPENAI_CHATGPT_MODEL_VERSION      = var.chatGptModelVersion
    EMBEDDING_DEPLOYMENT_NAME               = var.azureOpenAIEmbeddingDeploymentName
    AZURE_OPENAI_EMBEDDINGS_MODEL_NAME      = var.azureOpenAIEmbeddingsModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION   = var.azureOpenAIEmbeddingsModelVersion
    APPINSIGHTS_INSTRUMENTATIONKEY          = module.logging.applicationInsightsInstrumentationKey
    QUERY_TERM_LANGUAGE                     = var.queryTermLanguage
    AZURE_SUBSCRIPTION_ID                   = data.azurerm_client_config.current.subscription_id
    CHAT_WARNING_BANNER_TEXT                = var.chatWarningBannerText
    AZURE_AI_ENDPOINT                       = module.cognitiveServices.cognitiveServicesEndpoint
    AZURE_AI_LOCATION                       = var.location
    APPLICATION_TITLE                       = var.applicationtitle == "" ? "Information Assistant, built with Azure OpenAI" : var.applicationtitle
    USE_SEMANTIC_RERANKER                   = var.use_semantic_reranker
    BING_SEARCH_ENDPOINT                    = var.useWebChat ? module.bingSearch[0].endpoint : ""
    USE_WEB_CHAT                         = var.useWebChat
    USE_BING_SAFE_SEARCH                 = var.useBingSafeSearch
    USE_UNGROUNDED_CHAT                  = var.useUngroundedChat
    AZURE_AI_CREDENTIAL_DOMAIN               = var.azure_ai_private_link_domain
    TABLE_STORAGE_ACCOUNT_ENDPOINT           = module.storage.primary_table_endpoint
  }

  aadClientId = module.entraObjects.azure_ad_web_app_client_id
}

module "openaiServices" {
  source                            = "./core/ai/openaiservices"
  name                              = "infoasst-aoai-${random_string.random.result}"
  location                          = var.location
  tags                              = local.tags
  resourceGroupName                 = azurerm_resource_group.rg.name
  subnet_name                       = module.network.snetAzureOpenAI_name
  vnet_name                         = module.network.vnet_name
  subnet_id                         = module.network.snetAzureOpenAI_id
  private_dns_zone_ids              = [module.privateDnsZoneAzureOpenAi.privateDnsZoneResourceId]
  arm_template_schema_mgmt_api      = var.arm_template_schema_mgmt_api
  logAnalyticsWorkspaceResourceId   = module.logging.logAnalyticsId
  existingAzureOpenAIResourceGroup  = var.existingAzureOpenAIResourceGroup
  existingAzureOpenAIServiceName    = var.existingAzureOpenAIServiceName
  existingAzureOpenAILocation       = var.existingAzureOpenAILocation

  deployments = [
    {
      name            = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-4o")
      model           = {
        format        = "OpenAI"
        name          = var.chatGptModelName != "" ? var.chatGptModelName : "gpt-4o"
        version       = var.chatGptModelVersion != "" ? var.chatGptModelVersion : "2024-05-13"
      }
      sku             = {
        name          = var.chatGptModelSkuName
        capacity      = var.chatGptDeploymentCapacity
      }
      rai_policy_name = "Microsoft.Default"
    },
    {
      name            = var.azureOpenAIEmbeddingDeploymentName != "" ? var.azureOpenAIEmbeddingDeploymentName : "text-embedding-ada-002"
      model           = {
        format        = "OpenAI"
        name          = var.azureOpenAIEmbeddingsModelName != "" ? var.azureOpenAIEmbeddingsModelName : "text-embedding-ada-002"
        version       = var.azureOpenAIEmbeddingsModelVersion != "" ? var.azureOpenAIEmbeddingsModelVersion : "2"
      }
      sku             = {
        name          = var.azureOpenAIEmbeddingsModelSku
        capacity      = var.embeddingsDeploymentCapacity
      }
      rai_policy_name = "Microsoft.Default"
    }
  ]
}

module "aiDocIntelligence" {
  source                        = "./core/ai/docintelligence"
  name                          = "infoasst-docint-${random_string.random.result}"
  location                      = var.location
  tags                          = local.tags
  customSubDomainName           = "infoasst-docint-${random_string.random.result}"
  resourceGroupName             = azurerm_resource_group.rg.name
  subnet_name                   = module.network.snetAzureAi_name
  vnet_name                     = module.network.vnet_name
  private_dns_zone_ids          = [module.privateDnsZoneAzureAi.privateDnsZoneResourceId]
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
}

module "cognitiveServices" {
  source                        = "./core/ai/cogServices"
  name                          = "infoasst-aisvc-${random_string.random.result}"
  location                      = var.location 
  tags                          = local.tags
  resourceGroupName             = azurerm_resource_group.rg.name
  subnetResourceId              = module.network.snetAzureAi_id
  private_dns_zone_ids          = [module.privateDnsZoneAzureAi.privateDnsZoneResourceId]
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
  vnet_name                     = module.network.vnet_name
  subnet_name                   = module.network.snetAzureAi_name
}

module "searchServices" {
  source                          = "./core/search"
  name                            = var.searchServicesName != "" ? var.searchServicesName : "infoasst-search-${random_string.random.result}"
  location                        = var.location
  tags                            = local.tags
  semanticSearch                  = var.use_semantic_reranker ? "free": null
  resourceGroupName               = azurerm_resource_group.rg.name
  azure_search_domain             = var.azure_search_domain
  subnet_name                     = module.network.snetSearch_name
  vnet_name                       = module.network.vnet_name
  private_dns_zone_ids            = [module.privateDnsZoneSearchService.privateDnsZoneResourceId]
  arm_template_schema_mgmt_api    = var.arm_template_schema_mgmt_api
  storage_account_id              = module.storage.storage_account_id
  storage_account_name            = module.storage.name
  deployment_public_ip            = local.deployment_public_ip_list
  cognitive_services_account_id   = module.cognitiveServices.cognitiveServicesID
  cognitive_services_account_name = module.cognitiveServices.cognitiveServicesAccountName
  openai_services_account_id      = module.openaiServices.id
  openai_services_account_name    = module.openaiServices.name
  sku                             = var.searchServicesSkuName
  replica_count                   = var.searchServicesReplicaCount
}

module "azMonitor" {
  source            = "./core/logging/monitor"
  logAnalyticsName  = module.logging.logAnalyticsName
  location          = var.location
  logWorkbookName   = "infoasst-lw-${random_string.random.result}"
  resourceGroupName = azurerm_resource_group.rg.name 
  componentResource = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.OperationalInsights/workspaces/${module.logging.logAnalyticsName}"
}

// Bing Search is not supported in US Government
module "bingSearch" {
  count                         = var.azure_environment == "AzureUSGovernment" ? 0 : var.useWebChat ? 1 : 0
  source                        = "./core/ai/bingSearch"
  name                          = "infoasst-bing-${random_string.random.result}"
  resourceGroupName             = azurerm_resource_group.rg.name
  tags                          = local.tags
  sku                           = "S1" //supported SKUs can be found at https://www.microsoft.com/bing/apis/pricing
  arm_template_schema_mgmt_api  = var.arm_template_schema_mgmt_api
}

// USER ROLES
module "userRoles" {
  source = "./core/security/role"
  for_each = { for role in local.selected_roles : role => { role_definition_id = local.azure_roles[role] } }

  scope            = azurerm_resource_group.rg.id
  principalId      = data.azurerm_client_config.current.object_id 
  roleDefinitionId = each.value.role_definition_id
  principalType    = var.useCustomEntra ? "ServicePrincipal" : "User"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

data "azurerm_resource_group" "existing" {
  count = var.existingAzureOpenAIResourceGroup == "" ? 0 : 1
  name  = var.existingAzureOpenAIResourceGroup
}

# # // SYSTEM IDENTITY ROLES
module "webApp_OpenAiRole" {
  source = "./core/security/role"

  scope            = var.existingAzureOpenAIResourceGroup == "" ? azurerm_resource_group.rg.id : data.azurerm_resource_group.existing[0].id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "webApp_CognitiveServicesUser" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "webApp_StorageBlobDataContributor" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.StorageBlobDataContributor
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "webApp_SearchIndexDataReader" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.SearchIndexDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}
module "webApp_SearchServiceContributor" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.SearchServiceContributor
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "webApp_StorageTableDataContributor" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.StorageTableDataContributor
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "search_StorageBlobDataContributor" {
  source = "./core/security/role"
  scope            = module.storage.storage_account_id
  principalId      = module.searchServices.searchIdentity
  roleDefinitionId = local.azure_roles.StorageBlobDataContributor
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}
module "search_StorageTableDataContributor" {
  source = "./core/security/role"
  scope            = module.storage.storage_account_id
  principalId      = module.searchServices.searchIdentity
  roleDefinitionId = local.azure_roles.StorageTableDataContributor
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "search_CognitiveServicesUser" {
  source = "./core/security/role"
  scope            = module.cognitiveServices.cognitiveServicesID
  principalId      = module.searchServices.searchIdentity
  roleDefinitionId = local.azure_roles.CognitiveServicesUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "search_CognitiveServicesOpenAIUser" {
  source = "./core/security/role"
  scope            = var.existingAzureOpenAIResourceGroup == "" ? azurerm_resource_group.rg.id : data.azurerm_resource_group.existing[0].id
  principalId      = module.searchServices.searchIdentity
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "webApp_MonitoringMetricsPublisher" {
  source           = "./core/security/role"
  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.MonitoringMetricsPublisher
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "docIntel_StorageBlobDataReader" {
  source = "./core/security/role"
  scope = azurerm_resource_group.rg.id
  principalId = module.aiDocIntelligence.docIntelligenceIdentity
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType = "ServicePrincipal"
  subscriptionId = data.azurerm_client_config.current.subscription_id
  resourceGroupId = azurerm_resource_group.rg.id
}

# // MANAGEMENT SERVICE PRINCIPAL ROLES
module "openAiRoleMgmt" {
  source = "./core/security/role"
  # If leveraging an existing Azure OpenAI service, only make this assignment if not under automation.
  # When under automation and using an existing Azure OpenAI service, this will result in a duplicate assignment error.
  count = var.existingAzureOpenAIResourceGroup == "" ? 1 : var.useCustomEntra ? 0 : 1
  scope = var.existingAzureOpenAIResourceGroup == "" ? azurerm_resource_group.rg.id : data.azurerm_resource_group.existing[0].id
  principalId     = module.entraObjects.azure_ad_mgmt_sp_id
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType   = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

resource "azurerm_role_assignment" "key_vault_rbac_webapp" {
  scope                = module.kvModule.keyVaultId
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.webapp.identityPrincipalId
}

// DEPLOYMENT OF AZURE CUSTOMER ATTRIBUTION TAG
resource "azurerm_resource_group_template_deployment" "customer_attribution" {
  count               = var.useCUA ? 1 : 0
  name                = "pid-${var.cuaId}"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_content    = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": []
}
TEMPLATE
}