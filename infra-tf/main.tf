locals {
  abbrs  = jsondecode(file("${path.module}/abbreviations.json"))
  tags   = { ProjectName = "Information Assistant", BuildNumber = var.buildNumber }
  prefix = "infoasst"
  azure_roles = jsondecode(file("${path.module}/azure_roles.json"))
  selected_roles = ["CognitiveServicesOpenAIUser", "StorageBlobDataReader", "StorageBlobDataContributor", "SearchIndexDataReader", "SearchIndexDataContributor"]
}

data "azurerm_client_config" "current" {}

// Organize resources in a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName != "" ? var.resourceGroupName : "${local.prefix}-${var.environmentName}"
  location = var.location
  tags     = local.tags
}

module "logging" {
  source = "./core/logging/loganalytics"

  logAnalyticsName = var.logAnalyticsName != "" ? var.logAnalyticsName : "${local.prefix}-${local.abbrs["logAnalytics"]}${var.randomString}"
  applicationInsightsName = var.applicationInsightsName != "" ? var.applicationInsightsName : "${local.prefix}-${local.abbrs["appInsights"]}${var.randomString}"
  location = var.location
  tags = local.tags
  skuName = "PerGB2018"
  resourceGroupName = azurerm_resource_group.rg.name
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module "appServicePlan" {
  source = "./core/host/appplan"

  name     = var.appServicePlanName != "" ? var.appServicePlanName : "${local.prefix}-${local.abbrs["webServerFarms"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  sku = {
    tier = "Standard"
    size = "S1"
    capacity = 1
  }
  kind     = "linux"
  resourceGroupName = azurerm_resource_group.rg.name
}

// Create an App Service Plan for functions
module "funcServicePlan" {
  source = "./core/host/funcplan"

  name     = var.appServicePlanName != "" ? var.appServicePlanName : "${local.prefix}-${local.abbrs["funcServerFarms"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  sku = {
    size = "S2"
    tier = "Standard"
    capacity = 2
  }
  kind     = "linux"
  resourceGroupName = azurerm_resource_group.rg.name
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module "enrichmentAppServicePlan" {
  source = "./core/host/enrichmentplan"

  name     = var.enrichmentAppServicePlanName != "" ? var.enrichmentAppServicePlanName : "${local.prefix}-enrichment${local.abbrs["webServerFarms"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  sku = {
    size     = "P1v3"
    tier     = "PremiumV3"
    capacity = 3
  }
  kind     = "linux"
  reserved = true
  resourceGroupName = azurerm_resource_group.rg.name
  storageAccountId = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Storage/storageAccounts/${module.storage.name}/services/queue/queues/${var.embeddingsQueue}"
}


module "enrichmentApp" {
  source = "./core/host/enrichmentappservice"

  name = var.enrichmentServiceName != "" ? var.enrichmentServiceName : "${local.prefix}-enrichment${local.abbrs["webSitesAppService"]}${var.randomString}"
  appServicePlanId = module.enrichmentAppServicePlan.id
  location = var.location
  tags = local.tags
  runtimeName = "python"
  runtimeVersion = "3.10"
  linuxFxVersion = "PYTHON|3.10"
  scmDoBuildDuringDeployment = true
  managedIdentity = true
  logAnalyticsWorkspaceName = module.logging.logAnalyticsName
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId
  applicationInsightsName = module.logging.applicationInsightsName
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
  healthCheckPath = "/health"
  appCommandLine = "gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app"
  resourceGroupName = azurerm_resource_group.rg.name
  appSettings = {
    AZURE_BLOB_STORAGE_KEY = module.storage.key
    EMBEDDINGS_QUEUE = var.embeddingsQueue
    LOG_LEVEL = "DEBUG"
    DEQUEUE_MESSAGE_BATCH_SIZE = 1
    AZURE_BLOB_STORAGE_ACCOUNT = module.storage.name
    AZURE_BLOB_STORAGE_CONTAINER = var.containerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER = var.uploadContainerName
    AZURE_BLOB_STORAGE_ENDPOINT = module.storage.primary_endpoints
    COSMOSDB_URL = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_KEY = module.cosmosdb.CosmosDBKey
    COSMOSDB_LOG_DATABASE_NAME = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME = module.cosmosdb.CosmosDBLogContainerName
    COSMOSDB_TAGS_DATABASE_NAME = module.cosmosdb.CosmosDBTagsDatabaseName
    COSMOSDB_TAGS_CONTAINER_NAME = module.cosmosdb.CosmosDBTagsContainerName
    MAX_EMBEDDING_REQUEUE_COUNT = 5
    EMBEDDING_REQUEUE_BACKOFF = 60
    AZURE_OPENAI_SERVICE = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.cognitiveServices.name
    # AZURE_OPENAI_RESOURCE_GROUP: var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
    AZURE_OPENAI_SERVICE_KEY = var.useExistingAOAIService ? var.azureOpenAIServiceKey : module.cognitiveServices.key
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME = var.azureOpenAIEmbeddingDeploymentName
    AZURE_SEARCH_INDEX = var.searchIndexName
    AZURE_SEARCH_SERVICE_KEY = module.searchServices.searchServiceKey
    AZURE_SEARCH_SERVICE = module.searchServices.name
    BLOB_CONNECTION_STRING = module.storage.connection_string
    AZURE_STORAGE_CONNECTION_STRING = module.storage.connection_string
    TARGET_EMBEDDINGS_MODEL = var.useAzureOpenAIEmbeddings ? "${local.abbrs["openAIEmbeddingModel"]}${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    EMBEDDING_VECTOR_SIZE = var.useAzureOpenAIEmbeddings ? 1536 : var.sentenceTransformerEmbeddingVectorSize
    AZURE_SEARCH_SERVICE_ENDPOINT = module.searchServices.endpoint
    WEBSITES_CONTAINER_START_TIME_LIMIT = 600
  }
}

# // The application frontend
module "backend" {
  source = "./core/host/appservice"

  name = var.backendServiceName != "" ? var.backendServiceName : "${local.prefix}-${local.abbrs["webSitesAppService"]}${var.randomString}"
  location = var.location
  tags = merge(local.tags, { "azd-service-name" = "backend" })
  appServicePlanId = module.appServicePlan.id
  runtimeName = "python"
  runtimeVersion = "3.10"
  scmDoBuildDuringDeployment = true
  managedIdentity = true
  runtimeNameAndVersion = "python|3.10"
  linuxFxVersion = "PYTHON|3.10"
  appCommandLine = "gunicorn --workers 2 --worker-class uvicorn.workers.UvicornWorker app:app --timeout 600"
  applicationInsightsName = module.logging.applicationInsightsName
  logAnalyticsWorkspaceName = module.logging.logAnalyticsName
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId
  isGovCloudDeployment = var.isGovCloudDeployment
  portalURL = var.isGovCloudDeployment ? "https://portal.azure.us" : "https://portal.azure.com"
  enableOryxBuild = true
  resourceGroupName = azurerm_resource_group.rg.name
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.logging.applicationInsightsConnectionString
    AZURE_BLOB_STORAGE_ACCOUNT = module.storage.name
    AZURE_BLOB_STORAGE_ENDPOINT = module.storage.primary_endpoints
    AZURE_BLOB_STORAGE_CONTAINER = var.containerName
    AZURE_BLOB_STORAGE_UPLOAD_CONTAINER = var.uploadContainerName
    AZURE_BLOB_STORAGE_KEY = module.storage.key
    AZURE_OPENAI_SERVICE = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.cognitiveServices.name
    AZURE_OPENAI_RESOURCE_GROUP = var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
    AZURE_SEARCH_INDEX = var.searchIndexName
    AZURE_SEARCH_SERVICE = module.searchServices.name
    AZURE_SEARCH_SERVICE_ENDPOINT = module.searchServices.endpoint
    AZURE_SEARCH_SERVICE_KEY = module.searchServices.searchServiceKey
    AZURE_OPENAI_CHATGPT_DEPLOYMENT = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
    AZURE_OPENAI_CHATGPT_MODEL_NAME = var.chatGptModelName
    AZURE_OPENAI_CHATGPT_MODEL_VERSION = var.chatGptModelVersion
    USE_AZURE_OPENAI_EMBEDDINGS = var.useAzureOpenAIEmbeddings
    EMBEDDING_DEPLOYMENT_NAME = var.useAzureOpenAIEmbeddings ? var.azureOpenAIEmbeddingDeploymentName : var.sentenceTransformersModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_NAME = var.azureOpenAIEmbeddingsModelName
    AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION = var.azureOpenAIEmbeddingsModelVersion
    AZURE_OPENAI_SERVICE_KEY = var.useExistingAOAIService ? var.azureOpenAIServiceKey : module.cognitiveServices.key
    APPINSIGHTS_INSTRUMENTATIONKEY = module.logging.applicationInsightsInstrumentationKey
    COSMOSDB_URL = module.cosmosdb.CosmosDBEndpointURL
    COSMOSDB_KEY = module.cosmosdb.CosmosDBKey
    COSMOSDB_LOG_DATABASE_NAME = module.cosmosdb.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME = module.cosmosdb.CosmosDBLogContainerName
    COSMOSDB_TAGS_DATABASE_NAME = module.cosmosdb.CosmosDBTagsDatabaseName
    COSMOSDB_TAGS_CONTAINER_NAME = module.cosmosdb.CosmosDBTagsContainerName
    QUERY_TERM_LANGUAGE = var.queryTermLanguage
    AZURE_CLIENT_ID = module.entraRoles.azure_ad_mgmt_app_client_id #var.aadMgmtClientId
    AZURE_CLIENT_SECRET = module.entraRoles.azure_ad_mgmt_app_secret #var.aadMgmtClientSecret
    AZURE_TENANT_ID = var.tenantId
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
    IS_GOV_CLOUD_DEPLOYMENT = var.isGovCloudDeployment
    CHAT_WARNING_BANNER_TEXT = var.chatWarningBannerText
    TARGET_EMBEDDINGS_MODEL = var.useAzureOpenAIEmbeddings ? "${local.abbrs["openAIEmbeddingModel"]}${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    ENRICHMENT_APPSERVICE_NAME = module.enrichmentApp.name
    ENRICHMENT_KEY                         = module.enrichment.cognitiveServiceAccountKey
    ENRICHMENT_ENDPOINT                    = module.enrichment.cognitiveServiceEndpoint
    APPLICATION_TITLE = var.applicationtitle
  }

  aadClientId = module.entraRoles.azure_ad_web_app_client_id #var.aadWebClientId
}


module "cognitiveServices" {
  count = var.useExistingAOAIService ? 0 : 1
  source = "./core/ai/cogservices"

  name     = var.openAiServiceName != "" ? var.openAiServiceName : "${local.prefix}-${local.abbrs["openAIServices"]}${var.randomString}"
  customSubDomainName = var.openAiServiceName != "" ? var.openAiServiceName : "${local.prefix}-${local.abbrs["openAIServices"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  # sku = var.openAiSkuName

  deployments = [
    {
      name = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
      model_format = "OpenAI"
      model_name = var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k"
      model_version = var.chatGptModelVersion != "" ? var.chatGptModelVersion : "0613"
      sku_name = "Standard"
      sku_capacity = var.chatGptDeploymentCapacity
      rai_policy_name = "Microsoft.Default"
    },
    {
      name = var.azureOpenAIEmbeddingDeploymentName != "" ? var.azureOpenAIEmbeddingDeploymentName : var.azureOpenAIEmbeddingDeploymentName
      model_format = "OpenAI"
      model_name = var.azureOpenAIEmbeddingDeploymentName != "" ? var.azureOpenAIEmbeddingDeploymentName : "text-embedding-ada-002"
      model_version = "2"
      sku_name = "Standard"
      sku_capacity = var.embeddingsDeploymentCapacity
      rai_policy_name = "Microsoft.Default"
    }
  ]
}

module "formrecognizer" {
  source = "./core/ai/docintelligence"

  name     = "${local.prefix}-${local.abbrs["formRecognizer"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  # sku      = var.formRecognizerSkuName
  customSubDomainName = "${local.prefix}-${local.abbrs["formRecognizer"]}${var.randomString}"
  isGovCloudDeployment = var.isGovCloudDeployment
  resourceGroupName = azurerm_resource_group.rg.name
}

module "enrichment" {
  source = "./core/ai/cogenrichment"

  name     = "${local.prefix}-enrichment-${local.abbrs["cognitiveServicesAccounts"]}${var.randomString}"
  location = var.location 
  tags     = local.tags
  # sku = var.enrichmentSkuName
  isGovCloudDeployment = var.isGovCloudDeployment
  resourceGroupName = azurerm_resource_group.rg.name
}

module "searchServices" {
  source = "./core/search"

  name     = var.searchServicesName != "" ? var.searchServicesName : "${local.prefix}-${local.abbrs["searchSearchServices"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  # aad_auth_failure_mode = "http401WithBearerChallenge"
  # sku_name = var.searchServicesSkuName
  semanticSearch = "free"
  isGovCloudDeployment = var.isGovCloudDeployment
  resourceGroupName = azurerm_resource_group.rg.name
}

module "storage" {
  source = "./core/storage"

  name     = var.storageAccountName != "" ? var.storageAccountName : "${local.prefix}${local.abbrs["storageStorageAccounts"]}${var.randomString}"
  location = var.location
  tags     = local.tags
  # public_network_access_enabled = true
  # account_tier = "Standard"
  # account_replication_type = "LRS"
  # enable_https_traffic_only = true
  resourceGroupName = azurerm_resource_group.rg.name
  deleteRetentionPolicy = {
    days = 7
  }

  containers = [
    "content",
    "website",
    "upload",
    "function",
    "logs"
  ]

  queueNames = [
    "pdf-submit-queue",
    "pdf-polling-queue",
    "non-pdf-submit-queue",
    "media-submit-queue",
    "text-enrichment-queue",
    "image-enrichment-queue",
    "embeddings-queue"
  ]
}

module "cosmosdb" {
  source = "./core/db"

  name                = "${local.prefix}-${local.abbrs["cosmosDBAccounts"]}${var.randomString}"
  location            = var.location
  tags                = local.tags
  logDatabaseName   = "statusdb"
  logContainerName  = "statuscontainer"
  tagDatabaseName   = "tagdb"
  tagContainerName  = "tagcontainer"
  resourceGroupName = azurerm_resource_group.rg.name
}


# // Function App 
module "functions" {
  source = "./core/function"

  name                                  = var.functionsAppName != "" ? var.functionsAppName : "${local.prefix}-${local.abbrs["webSitesFunctions"]}${var.randomString}"
  location                              = var.location
  tags                                  = local.tags
  appServicePlanId                      = module.funcServicePlan.id

  runtime                               = "python"
  resourceGroupName                     = azurerm_resource_group.rg.name
  appInsightsConnectionString           = module.logging.applicationInsightsConnectionString
  appInsightsInstrumentationKey         = module.logging.applicationInsightsInstrumentationKey
  blobStorageAccountKey                 = module.storage.key
  blobStorageAccountName                = module.storage.name
  blobStorageAccountEndpoint            = module.storage.primary_endpoints
  blobStorageAccountConnectionString    = module.storage.connection_string
  blobStorageAccountOutputContainerName = var.containerName
  blobStorageAccountUploadContainerName = var.uploadContainerName
  blobStorageAccountLogContainerName    = var.functionLogsContainerName
  formRecognizerEndpoint                = module.formrecognizer.formRecognizerAccountEndpoint
  formRecognizerApiKey                  = module.formrecognizer.formRecognizerAccountKey
  CosmosDBEndpointURL                   = module.cosmosdb.CosmosDBEndpointURL
  CosmosDBKey                           = module.cosmosdb.CosmosDBKey
  CosmosDBLogDatabaseName               = module.cosmosdb.CosmosDBLogDatabaseName
  CosmosDBLogContainerName              = module.cosmosdb.CosmosDBLogContainerName
  CosmosDBTagsDatabaseName              = module.cosmosdb.CosmosDBTagsDatabaseName
  CosmosDBTagsContainerName             = module.cosmosdb.CosmosDBTagsContainerName
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
  enrichmentKey                         = module.enrichment.cognitiveServiceAccountKey
  enrichmentEndpoint                    = module.enrichment.cognitiveServiceEndpoint
  enrichmentName                        = module.enrichment.cognitiveServicerAccountName
  enrichmentLocation                    = var.location
  targetTranslationLanguage             = var.targetTranslationLanguage
  maxEnrichmentRequeueCount             = var.maxEnrichmentRequeueCount
  enrichmentBackoff                     = var.enrichmentBackoff
  enableDevCode                         = var.enableDevCode
  EMBEDDINGS_QUEUE                      = var.embeddingsQueue
  azureSearchIndex                      = var.searchIndexName
  azureSearchServiceEndpoint            = module.searchServices.endpoint
  azureSearchServiceKey                 = module.searchServices.searchServiceKey
  endpointSuffix                        = var.isGovCloudDeployment ? "core.usgovcloudapi.net" : "core.windows.net"

  depends_on = [
    module.appServicePlan,
    module.storage,
    module.cosmosdb
  ]
}


// USER ROLES
module "userRoles" {
  source = "./core/security/role"

  # for_each = { for idx, role_definition_id in var.role_definition_ids : idx => { role_definition_id = role_definition_id } }
  for_each = { for role in local.selected_roles : role => { role_definition_id = local.azure_roles[role] } }

  scope            = azurerm_resource_group.rg.id
  principalId      = data.azurerm_client_config.current.object_id #module.entraRoles.signed_in_user_principal #var.principalId
  roleDefinitionId = each.value.role_definition_id
  principalType    = var.isInAutomation ? "ServicePrincipal" : "User"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}


# # // SYSTEM IDENTITIES
module "openAiRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.backend.identityPrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}


module "ACRRoleContainerAppService" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId     = module.enrichmentApp.identityPrincipalId
  roleDefinitionId = local.azure_roles.AcrPull
  principalType   = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "storageRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.backend.identityPrincipalId
  roleDefinitionId = local.azure_roles.StorageBlobDataReader
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

module "searchRoleBackend" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.backend.identityPrincipalId
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

module "containerRegistryPush" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.entraRoles.azure_ad_mgmt_sp_id #var.aadMgmtServicePrincipalId
  roleDefinitionId = local.azure_roles.AcrPush
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

# // MANAGEMENT SERVICE PRINCIPAL
data "azurerm_resource_group" "existing" {
  count = var.useExistingAOAIService ? 1 : 0
  name  = var.azureOpenAIResourceGroup
}
module "openAiRoleMgmt" {
  source = "./core/security/role"
  count  = var.isInAutomation ? 0 : 1

  # scope            = var.useExistingAOAIService && !var.isGovCloudDeployment ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.id
  scope = var.useExistingAOAIService && !var.isGovCloudDeployment ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg.id
  principalId     = module.entraRoles.azure_ad_mgmt_sp_id #var.aadMgmtServicePrincipalId
  roleDefinitionId = local.azure_roles.CognitiveServicesOpenAIUser
  principalType   = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

# module "azMonitor" {
#   source = "./core/logging/monitor"

#   logAnalyticsName = module.logging.logAnalyticsName
#   location         = var.location
#   logWorkbookName = "${local.prefix}-${local.abbrs["logWorkbook"]}${var.randomString}"
#   resourceGroupName = azurerm_resource_group.rg.name 
#   componentResource = "/subscriptions/${var.subscriptionId}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.OperationalInsights/workspaces/${module.logging.logAnalyticsName}"
# }

module "kvModule" {
  source = "./core/security/keyvault"

  name                = "${local.prefix}-${local.abbrs["keyvault"]}${var.randomString}"
  location            = var.location
  kvAccessObjectId = data.azurerm_client_config.current.object_id #module.entraRoles.signed_in_user_principal #var.kvAccessObjectId
  searchServiceKey  = module.searchServices.searchServiceKey
  openaiServiceKey  = var.azureOpenAIServiceKey
  cosmosdbKey        = module.cosmosdb.CosmosDBKey 
  formRecognizerKey = module.formrecognizer.formRecognizerAccountKey
  blobConnectionString = module.storage.connection_string
  enrichmentKey      = module.enrichment.cognitiveServiceAccountKey
  spClientSecret    = module.entraRoles.azure_ad_mgmt_app_secret #var.aadMgmtClientSecret
  blobStorageKey    = module.storage.key 
  subscriptionId = var.subscriptionId
  resourceGroupId = azurerm_resource_group.rg.id
  resourceGroupName = azurerm_resource_group.rg.name
}

module "entraRoles" {
  source = "./core/aad"

  requireWebsiteSecurityMembership = var.requireWebsiteSecurityMembership
  randomString = var.randomString
  webAppSuffix = var.webAppSuffix
}

// DEPLOYMENT OF AZURE CUSTOMER ATTRIBUTION TAG
resource "azurerm_resource_group_template_deployment" "customer_attribution" {
  count               = var.cuaEnabled ? 1 : 0
  name                = "pid-${var.cuaId}"
  resource_group_name = var.resourceGroupName
  deployment_mode     = "Incremental"
  template_content    = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": []
}
TEMPLATE
}

