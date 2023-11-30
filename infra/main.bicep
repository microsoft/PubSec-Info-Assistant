targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@maxLength(5)
param randomString string

@minLength(1)
@description('Primary location for all resources')
param location string

param aadWebClientId string = ''
param aadMgmtClientId string = ''
@secure()
param aadMgmtClientSecret string = ''
param aadMgmtServicePrincipalId string = ''
param buildNumber string = 'local'
param isInAutomation bool = false
param useExistingAOAIService bool
param azureOpenAIServiceName string
param azureOpenAIResourceGroup string
@secure()
param azureOpenAIServiceKey string
param openAiServiceName string = ''
param openAiSkuName string = 'S0'
param cognitiveServiesForSearchName string = ''
param cosmosdbName string = ''
param formRecognizerName string = ''
param enrichmentName string = ''
param formRecognizerSkuName string = 'S0'
param enrichmentSkuName string = 'S0'
param cognitiveServiesForSearchSku string = 'S0'
param appServicePlanName string = ''
param enrichmentAppServicePlanName string = ''
param resourceGroupName string = ''
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param backendServiceName string = ''
param enrichmentServiceName string = ''
param functionsAppName string = ''
param mediaServiceName string = ''
param videoIndexerName string = ''
param searchServicesName string = ''
param searchServicesSkuName string = 'standard'
param storageAccountName string = ''
param containerName string = 'content'
param uploadContainerName string = 'upload'
param functionLogsContainerName string = 'logs'
param searchIndexName string = 'vector-index'
param chatGptDeploymentName string = 'gpt-35-turbo-16k'
param azureOpenAIEmbeddingDeploymentName string = 'text-embedding-ada-002'
param azureOpenAIEmbeddingsModelName string = 'text-embedding-ada-002'
param azureOpenAIEmbeddingsModelVersion string = '2'
param useAzureOpenAIEmbeddings bool = true
param sentenceTransformersModelName string = 'BAAI/bge-small-en-v1.5'
param sentenceTransformerEmbeddingVectorSize string = '384'
param embeddingsDeploymentCapacity int = 240
param chatWarningBannerText string = ''
param chatGptModelName string = 'gpt-35-turbo-16k'
param chatGptModelVersion string = '0613'
param chatGptDeploymentCapacity int = 240
// metadata in our chunking strategy adds about 180-200 tokens to the size of the chunks, 
// our default target size is 750 tokens so the chunk files that get indexed will be around 950 tokens each
param chunkTargetSize string = '750'
param targetPages string = 'ALL'
param formRecognizerApiVersion string = '2022-08-31'
param queryTermLanguage string = 'English'
param isGovCloudDeployment bool = contains(location, 'usgov')

// This block of variables are used by the enrichment pipeline
// Azure Functions or Container. These values are also populated
// in the debug env files at 'functions/local.settings.json'. You
// may want to update the local debug values separate from what is deployed to Azure.
param maxSecondsHideOnUpload string = '300'
param maxSubmitRequeueCount string = '10'
param pollQueueSubmitBackoff string = '60'
param pdfSubmitQueueBackoff string = '60'
param maxPollingRequeueCount string = '10'
param submitRequeueHideSeconds string = '1200'
param pollingBackoff string = '30'
param maxReadAttempts string = '5'
param maxEnrichmentRequeueCount string = '10'
param enrichmentBackoff string = '60'
param targetTranslationLanguage string = 'en'
param pdfSubmitQueue string = 'pdf-submit-queue'
param pdfPollingQueue string = 'pdf-polling-queue'
param nonPdfSubmitQueue string = 'non-pdf-submit-queue'
param mediaSubmitQueue string = 'media-submit-queue'
param textEnrichmentQueue string = 'text-enrichment-queue'
param imageEnrichmentQueue string = 'image-enrichment-queue'
param embeddingsQueue string = 'embeddings-queue'
// End of valued replicated in debug env files

// This block of variables are used for Branding
param applicationtitle string = ''
// End branding

param cuaEnabled bool = false
param cuaId string = ''
param enableDevCode bool = false
param tenantId string = ''
param subscriptionId string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''
param kvAccessObjectId string = ''

var abbrs = loadJsonContent('abbreviations.json')
var tags = { ProjectName: 'Information Assistant', BuildNumber: buildNumber }
var prefix = 'infoasst'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${prefix}-${environmentName}'
  location: location
  tags: tags
}

module logging 'core/logging/logging.bicep' = {
  name: 'logging'
  scope: rg
  params: {
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${prefix}-${abbrs.logAnalytics}${randomString}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${prefix}-${abbrs.appInsights}${randomString}'
    location: location
    tags: tags
    skuName: 'PerGB2018'
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${prefix}-${abbrs.webServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'S1'
      capacity: 3
    }
    kind: 'linux'
  }
}

// Create an App Service Plan for functions
module funcServicePlan 'core/host/funcserviceplan.bicep' = {
  name: 'funcserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${prefix}-${abbrs.funcServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'S3'
      capacity: 5
    }
    kind: 'linux'
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module enrichmentAppServicePlan 'core/host/enrichmentappserviceplan.bicep' = {
  name: 'enrichmentAppserviceplan'
  scope: rg
  params: {
    name: !empty(enrichmentAppServicePlanName) ? enrichmentAppServicePlanName : '${prefix}-enrichment${abbrs.webServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'P1v3'
      tier: 'PremiumV3'
      size: 'P1v3'
      family: 'Pv3'
      capacity: 3
    }
    kind: 'linux'
    reserved: true
    storageAccountId: '/subscriptions/${subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.Storage/storageAccounts/${storage.outputs.name}/services/queue/queues/${embeddingsQueue}'
  }
}

// Create an App Service Plan and supporting services for the enrichment app service
module enrichmentApp 'core/host/enrichmentappservice.bicep' = {
  name: 'enrichmentApp'
  scope: rg
  params: {
    name: !empty(enrichmentServiceName) ? enrichmentServiceName : '${prefix}-enrichment${abbrs.webSitesAppService}${randomString}'
    appServicePlanId: enrichmentAppServicePlan.outputs.id
    location: location
    tags: tags
    runtimeName: 'python'
    runtimeVersion: '3.10'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsName
    applicationInsightsName: logging.outputs.applicationInsightsName
    healthCheckPath: '/health'
    appCommandLine: 'gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app'
    appSettings: {
      AZURE_BLOB_STORAGE_KEY: storage.outputs.key
      EMBEDDINGS_QUEUE: embeddingsQueue
      LOG_LEVEL: 'DEBUG'
      DEQUEUE_MESSAGE_BATCH_SIZE: 1
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_UPLOAD_CONTAINER: uploadContainerName
      AZURE_BLOB_STORAGE_ENDPOINT: storage.outputs.primaryEndpoints.blob
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_KEY: cosmosdb.outputs.CosmosDBKey
      COSMOSDB_LOG_DATABASE_NAME: cosmosdb.outputs.CosmosDBLogDatabaseName
      COSMOSDB_LOG_CONTAINER_NAME: cosmosdb.outputs.CosmosDBLogContainerName
      COSMOSDB_TAGS_DATABASE_NAME: cosmosdb.outputs.CosmosDBTagsDatabaseName
      COSMOSDB_TAGS_CONTAINER_NAME: cosmosdb.outputs.CosmosDBTagsContainerName
      MAX_EMBEDDING_REQUEUE_COUNT: 5
      EMBEDDING_REQUEUE_BACKOFF: 60
      AZURE_OPENAI_SERVICE: useExistingAOAIService ? azureOpenAIServiceName : cognitiveServices.outputs.name
      AZURE_OPENAI_SERVICE_KEY: useExistingAOAIService ? azureOpenAIServiceKey : cognitiveServices.outputs.key
      AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME: azureOpenAIEmbeddingDeploymentName
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE_KEY: searchServices.outputs.searchServiceKey
      AZURE_SEARCH_SERVICE: searchServices.outputs.name
      BLOB_CONNECTION_STRING: storage.outputs.connectionString
      AZURE_STORAGE_CONNECTION_STRING: storage.outputs.connectionString
      TARGET_EMBEDDINGS_MODEL: useAzureOpenAIEmbeddings ? '${abbrs.openAIEmbeddingModel}${azureOpenAIEmbeddingDeploymentName}' : sentenceTransformersModelName
      EMBEDDING_VECTOR_SIZE: useAzureOpenAIEmbeddings ? 1536 : sentenceTransformerEmbeddingVectorSize
      AZURE_SEARCH_SERVICE_ENDPOINT: searchServices.outputs.endpoint
      WEBSITES_CONTAINER_START_TIME_LIMIT: 600
    }
  }
}

// The application frontend
module backend 'core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(backendServiceName) ? backendServiceName : '${prefix}-${abbrs.webSitesAppService}${randomString}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    applicationInsightsName: logging.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsName
    isGovCloudDeployment: isGovCloudDeployment
    appSettings: {
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_ENDPOINT: storage.outputs.primaryEndpoints.blob
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_UPLOAD_CONTAINER: uploadContainerName
      AZURE_BLOB_STORAGE_KEY: storage.outputs.key
      AZURE_OPENAI_SERVICE: useExistingAOAIService ? azureOpenAIServiceName : cognitiveServices.outputs.name
      AZURE_OPENAI_RESOURCE_GROUP: useExistingAOAIService ? azureOpenAIResourceGroup : rg.name
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchServices.outputs.name
      AZURE_SEARCH_SERVICE_ENDPOINT: searchServices.outputs.endpoint
      AZURE_SEARCH_SERVICE_KEY: searchServices.outputs.searchServiceKey
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: !empty(chatGptDeploymentName) ? chatGptDeploymentName : !empty(chatGptModelName) ? chatGptModelName : 'gpt-35-turbo-16k'
      AZURE_OPENAI_CHATGPT_MODEL_NAME: chatGptModelName
      AZURE_OPENAI_CHATGPT_MODEL_VERSION: chatGptModelVersion
      USE_AZURE_OPENAI_EMBEDDINGS: useAzureOpenAIEmbeddings
      EMBEDDING_DEPLOYMENT_NAME: useAzureOpenAIEmbeddings ? azureOpenAIEmbeddingDeploymentName : sentenceTransformersModelName
      AZURE_OPENAI_EMBEDDINGS_MODEL_NAME: azureOpenAIEmbeddingsModelName
      AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION: azureOpenAIEmbeddingsModelVersion
      AZURE_OPENAI_SERVICE_KEY: useExistingAOAIService ? azureOpenAIServiceKey : cognitiveServices.outputs.key
      APPINSIGHTS_INSTRUMENTATIONKEY: logging.outputs.applicationInsightsInstrumentationKey
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_KEY: cosmosdb.outputs.CosmosDBKey
      COSMOSDB_LOG_DATABASE_NAME: cosmosdb.outputs.CosmosDBLogDatabaseName
      COSMOSDB_LOG_CONTAINER_NAME: cosmosdb.outputs.CosmosDBLogContainerName
      COSMOSDB_TAGS_DATABASE_NAME: cosmosdb.outputs.CosmosDBTagsDatabaseName
      COSMOSDB_TAGS_CONTAINER_NAME: cosmosdb.outputs.CosmosDBTagsContainerName
      QUERY_TERM_LANGUAGE: queryTermLanguage
      AZURE_CLIENT_ID: aadMgmtClientId
      AZURE_CLIENT_SECRET: aadMgmtClientSecret
      AZURE_TENANT_ID: tenantId
      AZURE_SUBSCRIPTION_ID: subscriptionId
      IS_GOV_CLOUD_DEPLOYMENT: isGovCloudDeployment
      CHAT_WARNING_BANNER_TEXT: chatWarningBannerText
      TARGET_EMBEDDINGS_MODEL: useAzureOpenAIEmbeddings ? '${abbrs.openAIEmbeddingModel}${azureOpenAIEmbeddingDeploymentName}' : sentenceTransformersModelName
      ENRICHMENT_APPSERVICE_NAME: enrichmentApp.outputs.name
      APPLICATION_TITLE: applicationtitle
    }


    aadClientId: aadWebClientId
  }
}

module cognitiveServices 'core/ai/cognitiveservices.bicep' = if (!useExistingAOAIService) {
  name: 'openai'
  scope: rg
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${prefix}-${abbrs.openAIServices}${randomString}'
    location: location
    tags: tags
    sku: {
      name: openAiSkuName
    }
    deployments: [
      {
        name: !empty(chatGptDeploymentName) ? chatGptDeploymentName : !empty(chatGptModelName) ? chatGptModelName : 'gpt-35-turbo-16k'
        model: {
          format: 'OpenAI'
          name: !empty(chatGptModelName) ? chatGptModelName : 'gpt-35-turbo-16k'
          version: !empty(chatGptModelVersion) ? chatGptModelVersion : '0613'
        }
        sku: {
          name: 'Standard'
          capacity: chatGptDeploymentCapacity
        }
        raiPolicyName: 'Microsoft.Default'
      }
      {
        name: !empty(azureOpenAIEmbeddingDeploymentName) ? azureOpenAIEmbeddingDeploymentName : azureOpenAIEmbeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: !empty(azureOpenAIEmbeddingDeploymentName) ? azureOpenAIEmbeddingDeploymentName : 'text-embedding-ada-002'
          version: '2'
        }
        sku: {
          name: 'Standard'
          capacity: embeddingsDeploymentCapacity
        }
        raiPolicyName: 'Microsoft.Default'
      }
    ]
  }
}

module formrecognizer 'core/ai/formrecognizer.bicep' = {
  scope: rg
  name: 'formrecognizer'
  params: {
    name: !empty(formRecognizerName) ? formRecognizerName : '${prefix}-${abbrs.formRecognizer}${randomString}'
    location: location
    tags: tags
    sku: {
      name: formRecognizerSkuName
    }
    isGovCloudDeployment: isGovCloudDeployment
  }
}

module enrichment 'core/ai/enrichment.bicep' = {
  scope: rg
  name: 'enrichment'
  params: {
    name: !empty(enrichmentName) ? enrichmentName : '${prefix}-enrichment-${abbrs.cognitiveServicesAccounts}${randomString}'
    location: location
    tags: tags
    sku: enrichmentSkuName
    isGovCloudDeployment: isGovCloudDeployment
  }
}

module searchServices 'core/search/search-services.bicep' = {
  scope: rg
  name: 'search-services'
  params: {
    name: !empty(searchServicesName) ? searchServicesName : '${prefix}-${abbrs.searchSearchServices}${randomString}'
    location: location
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: searchServicesSkuName
    }
    semanticSearch: 'free'
    cogServicesName: !empty(cognitiveServiesForSearchName) ? cognitiveServiesForSearchName : '${prefix}-${abbrs.cognitiveServicesAccounts}${randomString}'
    cogServicesSku: {
      name: cognitiveServiesForSearchSku
    }
    isGovCloudDeployment: isGovCloudDeployment
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${prefix}${abbrs.storageStorageAccounts}${randomString}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    sku: {
      name: 'Standard_LRS'
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containers: [
      {
        name: containerName
        publicAccess: 'None'
      }
      {
        name: 'website'
        publicAccess: 'None'
      }
      {
        name: uploadContainerName
        publicAccess: 'None'
      }
      {
        name: 'function'
        publicAccess: 'None'
      }
      {
        name: functionLogsContainerName
        publicAccess: 'None'
      }
    ]
    queueNames: [
      {
        name: pdfSubmitQueue
      }
      {
        name: pdfPollingQueue
      }
      {
        name: nonPdfSubmitQueue
      }
      {
        name: mediaSubmitQueue
      }
      {
        name: textEnrichmentQueue
      }
      {
        name: imageEnrichmentQueue
      }
      {
        name: embeddingsQueue
      }
    ]
  }
}

module storageMedia 'core/storage/storage-account.bicep' = {
  name: 'storage-media'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${prefix}${abbrs.storageStorageAccounts}media${randomString}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    sku: {
      name: 'Standard_LRS'
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

module cosmosdb 'core/db/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: rg
  params: {
    name: !empty(cosmosdbName) ? cosmosdbName : '${prefix}-${abbrs.cosmosDBAccounts}${randomString}'
    location: location
    tags: tags
    logDatabaseName: 'statusdb'
    logContainerName: 'statuscontainer'
    tagDatabaseName: 'tagdb'
    tagContainerName: 'tagcontainer'
  }
}


// Function App 
module functions 'core/function/function.bicep' = {
  name: 'functions'
  scope: rg
  params: {
    name: !empty(functionsAppName) ? functionsAppName : '${prefix}-${abbrs.webSitesFunctions}${randomString}'
    location: location
    tags: tags
    appServicePlanId: funcServicePlan.outputs.id
    runtime: 'python'
    appInsightsConnectionString: logging.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: logging.outputs.applicationInsightsInstrumentationKey
    blobStorageAccountKey: storage.outputs.key
    blobStorageAccountName: storage.outputs.name
    blobStorageAccountEndpoint: storage.outputs.primaryEndpoints.blob
    blobStorageAccountConnectionString: storage.outputs.connectionString
    blobStorageAccountOutputContainerName: containerName
    blobStorageAccountUploadContainerName: uploadContainerName
    blobStorageAccountLogContainerName: functionLogsContainerName
    formRecognizerEndpoint: formrecognizer.outputs.formRecognizerAccountEndpoint
    formRecognizerApiKey: formrecognizer.outputs.formRecognizerAccountKey
    CosmosDBEndpointURL: cosmosdb.outputs.CosmosDBEndpointURL
    CosmosDBKey: cosmosdb.outputs.CosmosDBKey
    CosmosDBLogDatabaseName: cosmosdb.outputs.CosmosDBLogDatabaseName
    CosmosDBLogContainerName: cosmosdb.outputs.CosmosDBLogContainerName
    CosmosDBTagsDatabaseName: cosmosdb.outputs.CosmosDBTagsDatabaseName
    CosmosDBTagsContainerName: cosmosdb.outputs.CosmosDBTagsContainerName
    chunkTargetSize: chunkTargetSize
    targetPages: targetPages
    formRecognizerApiVersion: formRecognizerApiVersion
    pdfSubmitQueue: pdfSubmitQueue
    pdfPollingQueue: pdfPollingQueue
    nonPdfSubmitQueue: nonPdfSubmitQueue
    mediaSubmitQueue: mediaSubmitQueue
    maxSecondsHideOnUpload: maxSecondsHideOnUpload
    maxSubmitRequeueCount: maxSubmitRequeueCount
    pollQueueSubmitBackoff: pollQueueSubmitBackoff
    pdfSubmitQueueBackoff: pdfSubmitQueueBackoff
    textEnrichmentQueue: textEnrichmentQueue
    imageEnrichmentQueue: imageEnrichmentQueue
    maxPollingRequeueCount: maxPollingRequeueCount
    submitRequeueHideSeconds: submitRequeueHideSeconds
    pollingBackoff: pollingBackoff
    maxReadAttempts: maxReadAttempts
    enrichmentKey: enrichment.outputs.cognitiveServiceAccountKey
    enrichmentEndpoint: enrichment.outputs.cognitiveServiceEndpoint
    enrichmentName: enrichment.outputs.cognitiveServicerAccountName
    enrichmentLocation: location
    targetTranslationLanguage: targetTranslationLanguage
    maxEnrichmentRequeueCount: maxEnrichmentRequeueCount
    enrichmentBackoff: enrichmentBackoff
    enableDevCode: enableDevCode
    EMBEDDINGS_QUEUE: embeddingsQueue
    azureSearchIndex: searchIndexName
    azureSearchServiceEndpoint: searchServices.outputs.endpoint
    azureSearchServiceKey: searchServices.outputs.searchServiceKey

  }
  dependsOn: [
    appServicePlan
    storage
    cosmosdb
  ]
}

// Media Service
module media_service 'core/video_indexer/media_service.bicep' = {
  name: 'media_service'
  scope: rg
  params: {
    name: !empty(mediaServiceName) ? mediaServiceName : '${prefix}${abbrs.mediaService}${randomString}'
    location: location
    tags: tags
    storageAccountID: storageMedia.outputs.id
  }
}

// AVAM Service
module avam 'core/video_indexer/video_indexer.bicep' = {
  name: 'avam'
  scope: rg
  params: {
    name: !empty(videoIndexerName) ? videoIndexerName : '${prefix}${abbrs.videoIndexer}${randomString}'
    location: location
    tags: tags
    mediaServiceAccountResourceId: media_service.outputs.id
  }
}

// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module storageRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module storageContribRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-contribrole-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module searchRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module searchContribRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'search-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = {
  scope: rg
  name: 'openai-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module ACRRoleContainerAppService 'core/security/role.bicep' = {
  scope: rg
  name: 'container-webapp-acrpull-role'
  params: {
    principalId: enrichmentApp.outputs.identityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleBackend 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module searchRoleBackend 'core/security/role.bicep' = {
  scope: rg
  name: 'search-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleFunc 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-role-Func'
  params: {
    principalId: functions.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module containerRegistryPush 'core/security/role.bicep' = {
  scope: rg
  name: 'AcrPush'
  params: {
    principalId: aadMgmtServicePrincipalId
    roleDefinitionId: '8311e382-0749-4cb8-b61a-304f252e45ec'
    principalType: 'ServicePrincipal'
  }
}

// MANAGEMENT SERVICE PRINCIPAL
module openAiRoleMgmt 'core/security/role.bicep' = if (!isInAutomation) {
  scope: resourceGroup(useExistingAOAIService && !isGovCloudDeployment ? azureOpenAIResourceGroup : rg.name)
  name: 'openai-role-mgmt'
  params: {
    principalId: aadMgmtServicePrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module azMonitor 'core/logging/monitor.bicep' = {
  scope: rg
  name: 'azure-monitor'
  params: {
    location: location
    logWorkbookName: '${prefix}-${abbrs.logWorkbook}${randomString}'
    componentResource: '/subscriptions/${subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.OperationalInsights/workspaces/${logging.outputs.logAnalyticsName}'
  }
}

module kvModule 'core/security/keyvault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    name: '${prefix}-${abbrs.keyvault}${randomString}'
    location: location
    kvAccessObjectId: kvAccessObjectId
    searchServiceKey: searchServices.outputs.searchServiceKey 
    openaiServiceKey: azureOpenAIServiceKey
    cogServicesSearchKey: searchServices.outputs.cogServiceKey
    cosmosdbKey: cosmosdb.outputs.CosmosDBKey
    formRecognizerKey: formrecognizer.outputs.formRecognizerAccountKey
    blobConnectionString: storage.outputs.connectionString
    enrichmentKey: enrichment.outputs.cognitiveServiceAccountKey
    spClientSecret: aadMgmtClientSecret
    blobStorageKey: storage.outputs.key
  }
}

// DEPLOYMENT OF AZURE CUSTOMER ATTRIBUTION TAG
resource customerAttribution 'Microsoft.Resources/deployments@2021-04-01' = if (cuaEnabled) {
  name: 'pid-${cuaId}'
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}


output AZURE_LOCATION string = location
output AZURE_OPENAI_SERVICE string = azureOpenAIServiceName //cognitiveServices.outputs.name
output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchServices.outputs.name
output AZURE_SEARCH_SERVICE_ENDPOINT string = searchServices.outputs.endpoint
output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_ACCOUNT_ENDPOINT string = storage.outputs.primaryEndpoints.blob
output AZURE_STORAGE_CONTAINER string = containerName
output AZURE_STORAGE_UPLOAD_CONTAINER string = uploadContainerName
output BACKEND_URI string = backend.outputs.uri
output BACKEND_NAME string = backend.outputs.name
output RESOURCE_GROUP_NAME string = rg.name
output AZURE_OPENAI_CHAT_GPT_DEPLOYMENT string = !empty(chatGptDeploymentName) ? chatGptDeploymentName : !empty(chatGptModelName) ? chatGptModelName : 'gpt-35-turbo-16k'
output AZURE_OPENAI_RESOURCE_GROUP string = azureOpenAIResourceGroup
output AZURE_FUNCTION_APP_NAME string = functions.outputs.name
output AZURE_COSMOSDB_URL string = cosmosdb.outputs.CosmosDBEndpointURL
output AZURE_COSMOSDB_LOG_DATABASE_NAME string = cosmosdb.outputs.CosmosDBLogDatabaseName
output AZURE_COSMOSDB_LOG_CONTAINER_NAME string = cosmosdb.outputs.CosmosDBLogContainerName
output AZURE_COSMOSDB_TAGS_DATABASE_NAME string = cosmosdb.outputs.CosmosDBTagsDatabaseName
output AZURE_COSMOSDB_TAGS_CONTAINER_NAME string = cosmosdb.outputs.CosmosDBTagsContainerName
output AZURE_FORM_RECOGNIZER_ENDPOINT string = formrecognizer.outputs.formRecognizerAccountEndpoint
output AZURE_BLOB_DROP_STORAGE_CONTAINER string = uploadContainerName
output AZURE_BLOB_LOG_STORAGE_CONTAINER string = functionLogsContainerName
output CHUNK_TARGET_SIZE string = chunkTargetSize
output FR_API_VERSION string = formRecognizerApiVersion
output TARGET_PAGES string = targetPages
output AzureWebJobsStorage string = storage.outputs.connectionString
output ENRICHMENT_ENDPOINT string = enrichment.outputs.cognitiveServiceEndpoint
output ENRICHMENT_NAME string = enrichment.outputs.cognitiveServicerAccountName
output TARGET_TRANSLATION_LANGUAGE string = targetTranslationLanguage
output ENABLE_DEV_CODE bool = enableDevCode
output AZURE_CLIENT_ID string = aadMgmtClientId
output AZURE_TENANT_ID string = tenantId
output AZURE_SUBSCRIPTION_ID string = subscriptionId
output IS_USGOV_DEPLOYMENT bool = isGovCloudDeployment
output BLOB_STORAGE_ACCOUNT_ENDPOINT string = storage.outputs.primaryEndpoints.blob
output EMBEDDING_VECTOR_SIZE string = useAzureOpenAIEmbeddings ? '1536' : sentenceTransformerEmbeddingVectorSize
output TARGET_EMBEDDINGS_MODEL string = useAzureOpenAIEmbeddings ? '${abbrs.openAIEmbeddingModel}${azureOpenAIEmbeddingDeploymentName}' : sentenceTransformersModelName
output AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME string = azureOpenAIEmbeddingDeploymentName
output USE_AZURE_OPENAI_EMBEDDINGS bool = useAzureOpenAIEmbeddings
output EMBEDDING_DEPLOYMENT_NAME string = useAzureOpenAIEmbeddings ? azureOpenAIEmbeddingDeploymentName : sentenceTransformersModelName
output ENRICHMENT_APPSERVICE_NAME string = enrichmentApp.outputs.name 
output DEPLOYMENT_KEYVAULT_NAME string = kvModule.outputs.keyVaultName
