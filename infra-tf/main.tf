locals {
  abbrs  = jsondecode(file("${path.module}/abbreviations.json"))
  tags   = { ProjectName = "Information Assistant", BuildNumber = var.buildNumber }
  prefix = "infoasst"
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
    size = "S3"
    tier = "Standard"
  }
  # sku_capacity = 5
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
    size = "P1v3"
    tier = "PremiumV3"
  }
  # sku_tier = "PremiumV3"
  # sku_size = "P1v3"
  # sku_family = "Pv3"
  # sku_capacity = 3
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
    azureBlobStorageKey = module.storage.key
    embeddingsQueue = var.embeddingsQueue
    logLevel = "DEBUG"
    dequeueMessageBatchSize = 1
    azureBlobStorageAccount = module.storage.name
    azureBlobStorageContainer = var.containerName
    azureBlobStorageUploadContainer = var.uploadContainerName
    azureBlobStorageEndpoint = module.storage.primary_endpoints
    cosmosdbUrl = module.cosmosdb.CosmosDBEndpointURL
    cosmosdbKey = module.cosmosdb.CosmosDBKey
    cosmosdbLogDatabaseName = module.cosmosdb.CosmosDBLogDatabaseName
    cosmosdbLogContainerName = module.cosmosdb.CosmosDBLogContainerName
    cosmosdbTagsDatabaseName = module.cosmosdb.CosmosDBTagsDatabaseName
    cosmosdbTagsContainerName = module.cosmosdb.CosmosDBTagsContainerName
    maxEmbeddingRequeueCount = 5
    embeddingRequeueBackoff = 60
    azureOpenAIService = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.cognitiveServices.name
    azureOpenAIServiceKey = var.useExistingAOAIService ? var.azureOpenAIServiceKey : module.cognitiveServices.key
    azureOpenAIEmbeddingDeploymentName = var.azureOpenAIEmbeddingDeploymentName
    azureSearchIndex = var.searchIndexName
    azureSearchServiceKey = module.searchServices.searchServiceKey
    azureSearchService = module.searchServices.name
    blobConnectionString = module.storage.connection_string
    azureStorageConnectionString = module.storage.connection_string
    targetEmbeddingsModel = var.useAzureOpenAIEmbeddings ? "${local.abbrs["openAIEmbeddingModel"]}${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    embeddingVectorSize = var.useAzureOpenAIEmbeddings ? 1536 : var.sentenceTransformerEmbeddingVectorSize
    azureSearchServiceEndpoint = module.searchServices.endpoint
    websitesContainerStartTimeLimit = 600
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
  applicationInsightsName = module.logging.applicationInsightsName
  logAnalyticsWorkspaceName = module.logging.logAnalyticsName
  logAnalyticsWorkspaceResourceId = module.logging.logAnalyticsId
  isGovCloudDeployment = var.isGovCloudDeployment
  portalURL = var.isGovCloudDeployment ? "https://portal.azure.us" : "https://portal.azure.com"
  enableOryxBuild = true
  resourceGroupName = azurerm_resource_group.rg.name
  applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString

  app_settings = {
    applicationInsightsConnectionString = module.logging.applicationInsightsConnectionString
    azureBlobStorageAccount = module.storage.name
    azureBlobStorageEndpoint = module.storage.primary_endpoints
    azureBlobStorageContainer = var.containerName
    azureBlobStorageUploadContainer = var.uploadContainerName
    azureBlobStorageKey = module.storage.key
    azureOpenAIService = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.cognitiveServices.name
    azureOpenAIResourceGroup = var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
    azureSearchIndex = var.searchIndexName
    azureSearchService = module.searchServices.name
    azureSearchServiceEndpoint = module.searchServices.endpoint
    azureSearchServiceKey = module.searchServices.searchServiceKey
    azureOpenAIChatGptDeployment = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : (var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k")
    azureOpenAIChatGptModelName = var.chatGptModelName
    azureOpenAIChatGptModelVersion = var.chatGptModelVersion
    useAzureOpenAIEmbeddings = var.useAzureOpenAIEmbeddings
    embeddingDeploymentName = var.useAzureOpenAIEmbeddings ? var.azureOpenAIEmbeddingDeploymentName : var.sentenceTransformersModelName
    azureOpenAIEmbeddingsModelName = var.azureOpenAIEmbeddingsModelName
    azureOpenAIEmbeddingsModelVersion = var.azureOpenAIEmbeddingsModelVersion
    azureOpenAIServiceKey = var.useExistingAOAIService ? var.azureOpenAIServiceKey : module.cognitiveServices.key
    appInsightsInstrumentationKey = module.logging.applicationInsightsInstrumentationKey
    cosmosDbUrl = module.cosmosdb.CosmosDBEndpointURL
    cosmosDbKey = module.cosmosdb.CosmosDBKey
    cosmosDbLogDatabaseName = module.cosmosdb.CosmosDBLogDatabaseName
    cosmosDbLogContainerName = module.cosmosdb.CosmosDBLogContainerName
    cosmosDbTagsDatabaseName = module.cosmosdb.CosmosDBTagsDatabaseName
    cosmosDbTagsContainerName = module.cosmosdb.CosmosDBTagsContainerName
    queryTermLanguage = var.queryTermLanguage
    azureClientId = var.aadMgmtClientId
    azureClientSecret = var.aadMgmtClientSecret
    azureTenantId = var.tenantId
    azureSubscriptionId = var.subscriptionId
    isGovCloudDeployment = var.isGovCloudDeployment
    chatWarningBannerText = var.chatWarningBannerText
    targetEmbeddingsModel = var.useAzureOpenAIEmbeddings ? "${local.abbrs["openAIEmbeddingModel"]}${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
    enrichmentAppServiceName = module.enrichmentApp.name
    applicationTitle = var.applicationtitle
  }

  aadClientId = var.aadWebClientId
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
variable "role_definition_ids" {
  type    = list(string)
  default = ["5e0bd9bd-7b93-4f28-af87-19fc36ad61bd", #openAiRoleUser
             "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1", #storageRoleUser
             "ba92f5b4-2d11-453d-a403-e96b0029c9fe", #storageContribRoleUser
             "1407120a-92aa-4202-b7e9-c0e197c71c8f", #searchRoleUser
             "8ebe5a00-799e-43f5-93ac-243d3dce84a7"] #searchContribRoleUser
}

module "userRoles" {
  source = "./core/security/role"

  for_each = { for idx, role_definition_id in var.role_definition_ids : idx => { role_definition_id = role_definition_id } }

  scope            = azurerm_resource_group.rg.id
  principalId      = var.principalId
  roleDefinitionId = each.value.role_definition_id
  principalType    = var.isInAutomation ? "ServicePrincipal" : "User"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}


# # // SYSTEM IDENTITIES
# module "openAiRoleBackend" {
#   source = "./core/security/role"

#   scope            = azurerm_resource_group.rg.id
#   principalId      = module.backend.identityPrincipalId
#   roleDefinitionId = "5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
#   principalType    = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }


# module "ACRRoleContainerAppService" {
#   source = "./core/security/role"

#   scope            = azurerm_resource_group.rg.id
#   principalId     = module.enrichmentApp.identityPrincipalId
#   roleDefinitionId = "7f951dda-4ed3-4680-a7ca-43fe172d538d"
#   principalType   = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }

# module "storageRoleBackend" {
#   source = "./core/security/role"

#   scope            = azurerm_resource_group.rg.id
#   principalId      = module.backend.identityPrincipalId
#   roleDefinitionId = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
#   principalType    = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }

# module "searchRoleBackend" {
#   source = "./core/security/role"

#   scope            = azurerm_resource_group.rg.id
#   principalId      = module.backend.identityPrincipalId
#   roleDefinitionId = "1407120a-92aa-4202-b7e9-c0e197c71c8f"
#   principalType    = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }

module "storageRoleFunc" {
  source = "./core/security/role"

  scope            = azurerm_resource_group.rg.id
  principalId      = module.functions.function_app_identity_principal_id
  roleDefinitionId = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  principalType    = "ServicePrincipal"
  subscriptionId   = data.azurerm_client_config.current.subscription_id
  resourceGroupId  = azurerm_resource_group.rg.id
}

# module "containerRegistryPush" {
#   source = "./core/security/role"

#   scope            = azurerm_resource_group.rg.id
#   principalId      = var.aadMgmtServicePrincipalId
#   roleDefinitionId = "8311e382-0749-4cb8-b61a-304f252e45ec"
#   principalType    = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }

# # // MANAGEMENT SERVICE PRINCIPAL
# module "openAiRoleMgmt" {
#   source = "./core/security/role"
#   count  = var.isInAutomation ? 0 : 1

#   scope            = var.useExistingAOAIService && !var.isGovCloudDeployment ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
#   principalId     = var.aadMgmtServicePrincipalId
#   roleDefinitionId = "5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
#   principalType   = "ServicePrincipal"
#   subscriptionId   = data.azurerm_client_config.current.subscription_id
#   resourceGroupId  = azurerm_resource_group.rg.id
# }

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
  kvAccessObjectId = var.kvAccessObjectId
  searchServiceKey  = module.searchServices.searchServiceKey
  openaiServiceKey  = var.azureOpenAIServiceKey
  cosmosdbKey        = module.cosmosdb.CosmosDBKey 
  formRecognizerKey = module.formrecognizer.formRecognizerAccountKey
  blobConnectionString = module.storage.connection_string
  enrichmentKey      = module.enrichment.cognitiveServiceAccountKey
  spClientSecret    = var.aadMgmtClientSecret
  blobStorageKey    = module.storage.key 
  subscriptionId = var.subscriptionId
  resourceGroupId = azurerm_resource_group.rg.id
  resourceGroupName = azurerm_resource_group.rg.name
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

