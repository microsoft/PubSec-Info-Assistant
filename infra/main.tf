// Initialize Terraform configuration
locals {
  tags           = { ProjectName = "Information Assistant", BuildNumber = var.buildNumber }
  azure_roles    = jsondecode(file("${path.module}/azure_roles.json"))
  selected_roles = ["CognitiveServicesOpenAIUser", "StorageBlobDataReader", "StorageBlobDataContributor", "SearchIndexDataReader", "SearchIndexDataContributor"]
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
  tags     = local.tags
}

# Create Azure AD App Registrations and Service Principals
module "entraObjects" {
  source                           = "./core/aad"
  isInAutomation                   = var.isInAutomation
  requireWebsiteSecurityMembership = var.requireWebsiteSecurityMembership
  randomString                     = random_string.random.result
  azure_websites_domain            = var.azure_websites_domain
  aadWebClientId                   = var.aadWebClientId
  aadMgmtClientId                  = var.aadMgmtClientId
  aadMgmtServicePrincipalId        = var.aadMgmtServicePrincipalId
  aadMgmtClientSecret              = var.aadMgmtClientSecret
}

// Create the Virtual Network, Subnets, and Network Security Group
module "network" {
  source                     = "./core/network/network"
  count                      = var.is_secure_mode ? 1 : 0
  vnet_name                  = "infoasst-vnet-${random_string.random.result}"
  nsg_name                   = "infoasst-nsg-${random_string.random.result}"
  ddos_name                  = "infoasst-ddos-${random_string.random.result}"
  ddos_enabled               = var.ddos_enabled
  location                   = var.location
  tags                       = local.tags
  resourceGroupName          = azurerm_resource_group.rg.name
  vnetIpAddressCIDR          = var.virtual_network_CIDR
  snetAzureMonitorCIDR       = var.azure_monitor_CIDR
  snetStorageAccountCIDR     = var.storage_account_CIDR
  snetCosmosDbCIDR           = var.cosmos_db_CIDR
  snetAzureAiCIDR            = var.azure_ai_CIDR
  snetKeyVaultCIDR           = var.key_vault_CIDR
  snetAppCIDR                = var.webapp_CIDR
  SnetFunctionCIDR           = var.functions_CIDR
  snetEnrichmentCIDR          = var.enrichment_app_CIDR
  snetIntegrationCIDR        = var.integration_CIDR
  snetSearchServiceCIDR      = var.search_service_CIDR
  snetAzureVideoIndexerCIDR  = var.azure_video_indexer_CIDR
  snetBingServiceCIDR        = var.bing_service_CIDR
  snetAzureOpenAICIDR        = var.azure_openAI_CIDR
}

// Create the Private DNS Zones for all the services
module "privateDnsZoneAzureOpenAi" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_openai_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-azure-openai-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneAzureAi" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_ai_private_link_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-azure-ai-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneAzureAIVideoIndexer" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_ai_videoindexer_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-azure-ai-video-indexer-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneApp" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_websites_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-app-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneKeyVault" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_keyvault_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-kv-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneStorageAccountBlob" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.blob.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-blob-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneStorageAccountFile" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.file.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-file-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneStorageAccountTable" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.table.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-table-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneStorageAccountQueue" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.queue.${var.azure_storage_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-storage-queue-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneSearchService" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_search_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-search-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneCosmosDb" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.cosmosdb_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-cosmos-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

module "privateDnsZoneBingSearch" {
  source             = "./core/network/privateDNS"
  count              = var.is_secure_mode ? 1 : 0
  name               = "privatelink.${var.azure_bing_search_domain}"
  resourceGroupName  = azurerm_resource_group.rg.name
  vnetLinkName       = "infoasst-bingsearch-vnetlink-${random_string.random.result}"
  virtual_network_id = module.network[0].vnet_id
  tags               = local.tags
}

// Create the Azure Log Analytics and Application Insights
module "logging" {
  source = "./core/logging/loganalytics"
  logAnalyticsName                      = var.logAnalyticsName != "" ? var.logAnalyticsName : "infoasst-la-${random_string.random.result}"
  applicationInsightsName               = var.applicationInsightsName != "" ? var.applicationInsightsName : "infoasst-ai-${random_string.random.result}"
  location                              = var.location
  tags                                  = local.tags
  skuName                               = "PerGB2018"
  resourceGroupName                     = azurerm_resource_group.rg.name
  is_secure_mode                        = var.is_secure_mode
  privateLinkScopeName                  = "infoasst-ampls-${random_string.random.result}"
  vnetName                              = var.is_secure_mode ? module.network[0].vnet_name : ""
  privateDnsZoneNameMonitor             = "privatelink.${var.azure_monitor_domain}"
  privateDnsZoneNameOms                 = "privatelink.${var.azure_monitor_oms_domain}"
  privateDnSZoneNameOds                 = "privatelink.${var.azure_monitor_ods_domain}"
  privateDnsZoneNameAutomation          = "privatelink.${var.azure_automation_domain}"
  privateDnsZoneResourceIdBlob          = var.is_secure_mode ? module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneResourceId : null
  privateDnsZoneNameBlob                = var.is_secure_mode ? module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneName : null
  groupId                               = "azuremonitor"

}

// Create the storage account
module "storage" {
  source                = "./core/storage"
  is_secure_mode        = var.is_secure_mode
  name                  = var.storageAccountName != "" ? var.storageAccountName : "infoasststore${random_string.random.result}"
  location              = var.location
  tags                  = local.tags
  subscription_id       = data.azurerm_client_config.current.subscription_id
  accessTier            = "Hot"
  allowBlobPublicAccess = false
  publicNetworkAccess   = true
  resourceGroupName     = azurerm_resource_group.rg.name
  arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
  keyVaultId            = module.kvModule.keyVaultId
  deleteRetentionPolicy = {
    days                = 7
  }
  containers            = ["content", "website", "upload", "function", "logs", "config"]
  queueNames            = ["pdf-submit-queue", "pdf-polling-queue", "non-pdf-submit-queue", "media-submit-queue", "text-enrichment-queue", "image-enrichment-queue", "embeddings-queue"]
  subnetResourceId      = var.is_secure_mode ? module.network[0].snetStorageAccount_id : null
  private_dns_zone_ids  = var.is_secure_mode ? [module.privateDnsZoneStorageAccountBlob[0].privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountFile[0].privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountTable[0].privateDnsZoneResourceId,
                                        module.privateDnsZoneStorageAccountQueue[0].privateDnsZoneResourceId] : null
}

// Create the Enrichment Application
module "enrichmentApp" {
  source = "./core/host/enrichmentapp"

  name      = var.enrichmentServiceName != "" ? var.enrichmentServiceName : "infoasst-enrichmentweb-${random_string.random.result}"
  plan_name = var.enrichmentAppServicePlanName != "" ? var.enrichmentAppServicePlanName : "infoasst-enrichmentasp-${random_string.random.result}"
  location  = var.location
  tags      = local.tags
  sku = {
    size                                    = var.enrichmentAppServiceSkuSize
    tier                                    = var.enrichmentAppServiceSkuTier
    capacity                                = 3
  }
  kind                                = "linux"
  reserved                            = true
  resourceGroupName                   = azurerm_resource_group.rg.name
  storageAccountId                    = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${module.storage.name}/services/queue/queues/${var.embeddingsQueue}"
  scmDoBuildDuringDeployment          = true
  managedIdentity                     = true
  logAnalyticsWorkspaceResourceId     = module.logging.logAnalyticsId
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
  alwaysOn                            = true
  healthCheckPath                     = "/health"
  appCommandLine                      = "gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app"
  keyVaultUri                         = module.kvModule.keyVaultUri
  keyVaultName                        = module.kvModule.keyVaultName
  appSettings = {
    EMBEDDINGS_QUEUE                       = var.embeddingsQueue
    LOG_LEVEL                              = "DEBUG"
    DEQUEUE_MESSAGE_BATCH_SIZE             = 1
    AZURE_BLOB_STORAGE_ACCOUNT             = module.storage.name
    AZURE_BLOB_STORAGE_CONTAINER           = var.contentContainerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER    = var.uploadContainerName
    AZURE_BLOB_STORAGE_ENDPOINT            = module.storage.primary_endpoints
    COSMOSDB_URL                           = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_LOG_DATABASE_NAME             = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME            = module.cosmosdb.CosmosDBLogContainerName
    MAX_EMBEDDING_REQUEUE_COUNT            = 5
    EMBEDDING_REQUEUE_BACKOFF              = 60
    AZURE_OPENAI_SERVICE                   = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.openaiServices.name
    AZURE_OPENAI_ENDPOINT                  = var.useExistingAOAIService ? "https://${var.azureOpenAIServiceName}.${var.azure_openai_domain}/" : module.openaiServices.endpoint
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME = var.azureOpenAIEmbeddingDeploymentName
    AZURE_SEARCH_INDEX                     = var.searchIndexName
    AZURE_SEARCH_SERVICE                   = module.searchServices.name
    TARGET_EMBEDDINGS_MODEL                = var.useAzureOpenAIEmbeddings ? "azure-openai_${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    EMBEDDING_VECTOR_SIZE                  = var.useAzureOpenAIEmbeddings ? 1536 : var.sentenceTransformerEmbeddingVectorSize
    AZURE_SEARCH_SERVICE_ENDPOINT          = module.searchServices.endpoint
    WEBSITES_CONTAINER_START_TIME_LIMIT    = 600
  }
  depends_on = [module.kvModule]
}

// Create the Web App
module "webapp" {
  source                              = "./core/host/webapp"
  name                                = var.webappServiceName != "" ? var.webappServiceName : "infoasst-web-${random_string.random.result}"
  plan_name                           = var.appServicePlanName != "" ? var.appServicePlanName : "infoasst-asp-${random_string.random.result}"
  sku = {
    tier                              = var.appServiceSkuTier
    size                              = var.appServiceSkuSize
    capacity                          = 1
  }
  kind                                = "linux"
  resourceGroupName                   = azurerm_resource_group.rg.name
  location                            = var.location
  tags                                = merge(local.tags, { "azd-service-name" = "webapp" })
  runtimeVersion                      = "3.10"
  scmDoBuildDuringDeployment          = true
  managedIdentity                     = true
  appCommandLine                      = "gunicorn --workers 2 --worker-class uvicorn.workers.UvicornWorker app:app --timeout 600"
  logAnalyticsWorkspaceResourceId     = module.logging.logAnalyticsId
  azure_portal_domain                 = var.azure_portal_domain
  enableOryxBuild                     = true
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
  keyVaultUri                         = module.kvModule.keyVaultUri
  keyVaultName                        = module.kvModule.keyVaultName
  tenantId                            = var.tenantId
  is_secure_mode                      = var.is_secure_mode
  subnet_id                           = var.is_secure_mode ? module.network[0].snetApp_id : null
  snetIntegration_id                  = var.is_secure_mode ? module.network[0].snetIntegration_id : null
  private_dns_zone_ids                = var.is_secure_mode ? [module.privateDnsZoneApp[0].privateDnsZoneResourceId] : null
  private_dns_zone_name               = var.is_secure_mode ? module.privateDnsZoneApp[0].privateDnsZoneName : null

  appSettings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING   = module.logging.applicationInsightsConnectionString
    AZURE_BLOB_STORAGE_ACCOUNT              = module.storage.name
    AZURE_BLOB_STORAGE_ENDPOINT             = module.storage.primary_endpoints
    AZURE_BLOB_STORAGE_CONTAINER            = var.contentContainerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER     = var.uploadContainerName
    AZURE_OPENAI_SERVICE                    = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.openaiServices.name
    AZURE_OPENAI_RESOURCE_GROUP             = var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
    AZURE_OPENAI_ENDPOINT                   = var.useExistingAOAIService ? "https://${var.azureOpenAIServiceName}.${var.azure_openai_domain}/" : module.openaiServices.endpoint
    AZURE_OPENAI_AUTHORITY_HOST             = var.azure_openai_authority_host
    AZURE_ARM_MANAGEMENT_API                = var.azure_arm_management_api
    AZURE_SEARCH_INDEX                      = var.searchIndexName
    AZURE_SEARCH_SERVICE                    = module.searchServices.name
    AZURE_SEARCH_SERVICE_ENDPOINT           = module.searchServices.endpoint
    AZURE_OPENAI_CHATGPT_DEPLOYMENT         = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
    AZURE_OPENAI_CHATGPT_MODEL_NAME         = var.chatGptModelName
    AZURE_OPENAI_CHATGPT_MODEL_VERSION      = var.chatGptModelVersion
    USE_AZURE_OPENAI_EMBEDDINGS             = var.useAzureOpenAIEmbeddings
    EMBEDDING_DEPLOYMENT_NAME               = var.useAzureOpenAIEmbeddings ? var.azureOpenAIEmbeddingDeploymentName : var.sentenceTransformersModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_NAME      = var.azureOpenAIEmbeddingsModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION   = var.azureOpenAIEmbeddingsModelVersion
    APPINSIGHTS_INSTRUMENTATIONKEY          = module.logging.applicationInsightsInstrumentationKey
    COSMOSDB_URL                            = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_LOG_DATABASE_NAME              = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME             = module.cosmosdb.CosmosDBLogContainerName
    QUERY_TERM_LANGUAGE                     = var.queryTermLanguage
    AZURE_SUBSCRIPTION_ID                   = data.azurerm_client_config.current.subscription_id
    CHAT_WARNING_BANNER_TEXT                = var.chatWarningBannerText
    TARGET_EMBEDDINGS_MODEL                 = var.useAzureOpenAIEmbeddings ? "azure-openai_${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    ENRICHMENT_APPSERVICE_URL               = module.enrichmentApp.uri
    ENRICHMENT_ENDPOINT                     = module.cognitiveServices.cognitiveServiceEndpoint
    APPLICATION_TITLE                       = var.applicationtitle == "" ? "Information Assistant, built with Azure OpenAI" : var.applicationtitle
    AZURE_AI_TRANSLATION_DOMAIN             = var.azure_ai_translation_domain
    USE_SEMANTIC_RERANKER                   = var.use_semantic_reranker
    BING_SEARCH_ENDPOINT                    = var.enableWebChat ? module.bingSearch[0].endpoint : ""
    BING_SEARCH_KEY                         = var.enableWebChat ? module.bingSearch[0].key : ""
    ENABLE_WEB_CHAT                         = var.enableWebChat
    ENABLE_BING_SAFE_SEARCH                 = var.enableBingSafeSearch
    ENABLE_UNGROUNDED_CHAT                  = var.enableUngroundedChat
    ENABLE_MATH_ASSISTANT                   = var.enableMathAssitant
    ENABLE_TABULAR_DATA_ASSISTANT           = var.enableTabularDataAssistant
    ENABLE_MULTIMEDIA                       = var.enableMultimedia
  }

  aadClientId = module.entraObjects.azure_ad_web_app_client_id
  depends_on  = [module.kvModule]
}

// Create the Azure OpenAI Service and Model deployments
module "openaiServices" {
  source                 = "./core/ai/openaiservices"
  is_secure_mode         = var.is_secure_mode
  name                   = var.openAIServiceName != "" ? var.openAIServiceName : "infoasst-aoai-${random_string.random.result}"
  location               = var.location
  tags                   = local.tags
  resourceGroupName      = azurerm_resource_group.rg.name
  keyVaultId             = module.kvModule.keyVaultId
  openaiServiceKey       = var.azureOpenAIServiceKey
  useExistingAOAIService = var.useExistingAOAIService
  subnetResourceId       = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  private_dns_zone_ids   = var.is_secure_mode ? [module.privateDnsZoneAzureOpenAi[0].privateDnsZoneResourceId] : null

  deployments = [
    {
      name               = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
      model              = {
        format           = "OpenAI"
        name             = var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k"
        version          = var.chatGptModelVersion != "" ? var.chatGptModelVersion : "0613"
      }
      sku_name           = "Standard"
      sku_capacity       = var.chatGptDeploymentCapacity
      rai_policy_name    = "Microsoft.Default"
    },
    {
      name               = var.azureOpenAIEmbeddingDeploymentName != "" ? var.azureOpenAIEmbeddingDeploymentName : "text-embedding-ada-002"
      model              = {
        format           = "OpenAI"
        name             = var.azureOpenAIEmbeddingsModelName != "" ? var.azureOpenAIEmbeddingsModelName : "text-embedding-ada-002"
        version          = "2"
      }
      sku_name        = "Standard"
      sku_capacity    = var.embeddingsDeploymentCapacity
      rai_policy_name = "Microsoft.Default"
    }
  ]
}


// Create the AI Document Intelligence Service
module "aiDocIntelligence" {
  source               = "./core/ai/docintelligence"
  is_secure_mode       = var.is_secure_mode
  name                 = "infoasst-dint-${random_string.random.result}"
  location             = var.location
  tags                 = local.tags
  customSubDomainName  = "infoasst-dint-${random_string.random.result}"
  resourceGroupName    = azurerm_resource_group.rg.name
  keyVaultId           = module.kvModule.keyVaultId
  subnetResourceId     = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  private_dns_zone_ids = var.is_secure_mode ? [module.privateDnsZoneAzureAi[0].privateDnsZoneResourceId] : null

}

// Create the AI Services for Text Enrichment
module "cognitiveServices" {
  source                = "./core/ai/cogServices"
  is_secure_mode        = var.is_secure_mode
  name                  = "infoasst-enrichment-cog-${random_string.random.result}"
  location              = var.location
  tags                  = local.tags
  keyVaultId            = module.kvModule.keyVaultId
  resourceGroupName     = azurerm_resource_group.rg.name
  subnetResourceId      = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  private_dns_zone_ids  = var.is_secure_mode ? [module.privateDnsZoneAzureAi[0].privateDnsZoneResourceId] : null
}

// Create the Azure Search Service
module "searchServices" {
  source                = "./core/search"
  is_secure_mode        = var.is_secure_mode
  name                  = var.searchServicesName != "" ? var.searchServicesName : "infoasst-search-${random_string.random.result}"
  location              = var.location
  tags                  = local.tags
  semanticSearch        = var.use_semantic_reranker ? "free" : null
  resourceGroupName     = azurerm_resource_group.rg.name
  keyVaultId            = module.kvModule.keyVaultId
  azure_search_domain   = var.azure_search_domain
  subnetResourceId      = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  private_dns_zone_ids  = var.is_secure_mode ? [module.privateDnsZoneSearchService[0].privateDnsZoneResourceId] : null
}

// Create the CosmosDB Service
module "cosmosdb" {
  source               = "./core/db"
  is_secure_mode       = var.is_secure_mode
  name                 = "infoasst-cosmos-${random_string.random.result}"
  location             = var.location
  tags                 = local.tags
  logDatabaseName      = "statusdb"
  logContainerName     = "statuscontainer"
  resourceGroupName    = azurerm_resource_group.rg.name
  keyVaultId           = module.kvModule.keyVaultId
  subnetResourceId     = var.is_secure_mode ? module.network[0].snetCosmosDb_id : null
  private_dns_zone_ids = var.is_secure_mode ? [module.privateDnsZoneCosmosDb[0].privateDnsZoneResourceId] : null
}

// Create Function App 
module "functions" {
  source = "./core/host/functions"

  name                                  = var.functionsAppName != "" ? var.functionsAppName : "infoasst-func-${random_string.random.result}"
  location                              = var.location
  tags                                  = local.tags
  keyVaultUri                           = module.kvModule.keyVaultUri
  keyVaultName                          = module.kvModule.keyVaultName 
  plan_name                             = var.appServicePlanName != "" ? var.appServicePlanName : "infoasst-func-asp-${random_string.random.result}"
  sku                                   = {
    size                                = var.functionsAppSkuSize
    tier                                = var.functionsAppSkuTier
    capacity                            = 2
  }
  kind                                  = "linux"
  runtime                               = "python"
  resourceGroupName                     = azurerm_resource_group.rg.name
  appInsightsConnectionString           = module.logging.applicationInsightsConnectionString
  appInsightsInstrumentationKey         = module.logging.applicationInsightsInstrumentationKey
  blobStorageAccountName                = module.storage.name
  blobStorageAccountEndpoint            = module.storage.primary_endpoints
  blobStorageAccountOutputContainerName = var.contentContainerName
  blobStorageAccountUploadContainerName = var.uploadContainerName
  blobStorageAccountLogContainerName    = var.functionLogsContainerName
  formRecognizerEndpoint                = module.aiDocIntelligence.formRecognizerAccountEndpoint
  CosmosDBEndpointURL                   = module.cosmosdb.CosmosDBEndpointURL
  CosmosDBLogDatabaseName               = module.cosmosdb.CosmosDBLogDatabaseName
  CosmosDBLogContainerName              = module.cosmosdb.CosmosDBLogContainerName
  chunkTargetSize                       = var.chunkTargetSize
  targetPages                           = var.targetPages
  formRecognizerApiVersion              = var.formRecognizerApiVersion
  pdfSubmitQueue                        = var.pdfSubmitQueue
  pdfPollingQueue                       = var.pdfPollingQueue
  nonPdfSubmitQueue                     = var.nonPdfSubmitQueue
  mediaSubmitQueue                      = var.mediaSubmitQueue
  maxSecondsHideOnUpload                = var.maxSecondsHideOnUpload
  maxSubmitRequeueCount                 = var.maxSubmitRequeueCount
  pollQueueSubmitBackoff                = var.pollQueueSubmitBackoff
  pdfSubmitQueueBackoff                 = var.pdfSubmitQueueBackoff
  textEnrichmentQueue                   = var.textEnrichmentQueue
  imageEnrichmentQueue                  = var.imageEnrichmentQueue
  maxPollingRequeueCount                = var.maxPollingRequeueCount
  submitRequeueHideSeconds              = var.submitRequeueHideSeconds
  pollingBackoff                        = var.pollingBackoff
  maxReadAttempts                       = var.maxReadAttempts
  enrichmentEndpoint                    = module.cognitiveServices.cognitiveServiceEndpoint
  enrichmentName                        = module.cognitiveServices.cognitiveServicerAccountName
  enrichmentLocation                    = var.location
  targetTranslationLanguage             = var.targetTranslationLanguage
  maxEnrichmentRequeueCount             = var.maxEnrichmentRequeueCount
  enrichmentBackoff                     = var.enrichmentBackoff
  enableDevCode                         = var.enableDevCode
  EMBEDDINGS_QUEUE                      = var.embeddingsQueue
  azureSearchIndex                      = var.searchIndexName
  azureSearchServiceEndpoint            = module.searchServices.endpoint
  endpointSuffix                        = var.azure_storage_domain
  azure_ai_text_analytics_domain        = var.azure_ai_text_analytics_domain
  azure_ai_translation_domain           = var.azure_ai_translation_domain

  depends_on = [
    module.storage,
    module.cosmosdb,
    module.kvModule
  ]
}

// Create the SharePoint Connector logic app
module "sharepoint" {
  count                = var.enableSharePointConnector ? 1 : 0
  source               = "./core/sharepoint"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  resource_group_id    = azurerm_resource_group.rg.id
  subscription_id      = data.azurerm_client_config.current.subscription_id
  storage_account_name = module.storage.name
  storage_access_key   = module.storage.storage_account_access_key
  random_string        = random_string.random.result
  tags                 = local.tags

  depends_on = [
    module.storage
  ]
}

// Create the Azure AI Video Indexer
module "video_indexer" {
  count                               = var.enableMultimedia ? 1 : 0
  source                              = "./core/videoindexer"
  location                            = azurerm_resource_group.rg.location
  resource_group_name                 = azurerm_resource_group.rg.name
  subscription_id                     = data.azurerm_client_config.current.subscription_id
  random_string                       = random_string.random.result
  tags                                = local.tags
  azuread_service_principal_object_id = module.entraObjects.azure_ad_web_app_client_id
  arm_template_schema_mgmt_api        = var.arm_template_schema_mgmt_api
  video_indexer_api_version           = var.video_indexer_api_version
  subnet_id                           = var.is_secure_mode ? module.network[0].snetAzureAi_id : null
  privateDnsZoneName                  = var.is_secure_mode ? module.privateDnsZoneAzureAIVideoIndexer[0].privateDnsZoneName : null
}

// Create the Azure Key Vault
module "kvModule" {
  source            = "./core/security/keyvault"
  name              = "infoasst-kv-${random_string.random.result}"
  location          = var.location
  kvAccessObjectId  = data.azurerm_client_config.current.object_id
  spClientSecret    = module.entraObjects.azure_ad_mgmt_app_secret
  subscriptionId    = var.subscriptionId
  resourceGroupId   = azurerm_resource_group.rg.id
  resourceGroupName = azurerm_resource_group.rg.name
  tags              = local.tags
}

// Create the Bing v7 Search Service
module "bingSearch" {
  count                        = var.enableWebChat ? 1 : 0
  source                       = "./core/ai/bingSearch"
  name                         = "infoasst-bing-${random_string.random.result}"
  resourceGroupName            = azurerm_resource_group.rg.name
  tags                         = local.tags
  sku                          = "S1" //supported SKUs can be found at https://www.microsoft.com/en-us/bing/apis/pricing
  arm_template_schema_mgmt_api = var.arm_template_schema_mgmt_api
}

// Create User Security roles
module "userRoles" {
  source   = "./core/security/role"
  for_each = { for role in local.selected_roles : role => { role_definition_id = local.azure_roles[role] } }

  scope            = azurerm_resource_group.rg.id
  principalId      = data.azurerm_client_config.current.object_id
  roleDefinitionId = each.value.role_definition_id
  principalType    = var.isInAutomation ? "ServicePrincipal" : "User"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

data "azurerm_resource_group" "existing" {
  count = var.useExistingAOAIService ? 1 : 0
  name  = var.azureOpenAIResourceGroup
}

# Create System Identity Security roles

module "openAiRoleBackend" {
  source = "./core/security/role"

  scope            = var.useExistingAOAIService ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "storageRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "searchRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.webapp.identityPrincipalId
  roleDefinitionId = local.azure_roles.SearchIndexDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "storageRoleFunc" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.functions.function_app_identity_principal_id
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "aviRoleWebapp" {
  source            = "./core/security/role"
  count             = var.enableMultimedia ? 1 : 0
  scope             = module.video_indexer[0].vi_id
  principalId       = module.webapp.identityPrincipalId
  roleDefinitionId  = local.azure_roles.Contributor
  principalType     = "ServicePrincipal"
  subscriptionId    = data.azurerm_client_config.current.subscription_id
  resourceGroupId   = azurerm_resource_group.rg.id 
}

// Create Management Security roles

module "openAiRoleMgmt" {
  source = "./core/security/role"
  # If leveraging an existing Azure OpenAI service, only make this assignment if not under automation.
  # When under automation and using an existing Azure OpenAI service, this will result in a duplicate assignment error.
  count            = var.useExistingAOAIService ? var.isInAutomation ? 0 : 1 : 1
  scope            = var.useExistingAOAIService ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg.id
  principalId      = module.entraObjects.azure_ad_mgmt_sp_id
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

// Create the Azure Workbook for monitoring
module "azWorkbook" {
  source            = "./core/logging/workbook"
  logAnalyticsName  = module.logging.logAnalyticsName
  location          = var.location
  logWorkbookName   = "infoasst-lw-${random_string.random.result}"
  resourceGroupName = azurerm_resource_group.rg.name
  componentResource = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.OperationalInsights/workspaces/${module.logging.logAnalyticsName}"
}

// Create the customer attribution tag for the resource group
resource "azurerm_resource_group_template_deployment" "customer_attribution" {
  count               = var.cuaEnabled ? 1 : 0
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

