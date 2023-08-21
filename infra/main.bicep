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

param aadClientId string = ''
param buildNumber string = 'local'
param isInAutomation bool = false
param useExistingAOAIService bool
param azureOpenAIServiceName string
param azureOpenAIServiceKey string
param openAiServiceName string = ''
param openAiSkuName string = 'S0'
param cognitiveServiesForSearchName string = ''
param cosmosdbName string = ''
param formRecognizerName string = ''
param enrichmentName string = ''
param formRecognizerSkuName string = 'S0'
param encichmentSkuName string = 'S0'
param cognitiveServiesForSearchSku string = 'S0'
param appServicePlanName string = ''
param resourceGroupName string = ''
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param backendServiceName string = ''
param functionsAppName string = ''
param mediaServiceName string = ''
param videoIndexerName string = ''
param searchServicesName string = ''
param searchServicesSkuName string = 'standard'
param storageAccountName string = ''
param containerName string = 'content'
param uploadContainerName string = 'upload'
param functionLogsContainerName string = 'logs'
param searchIndexName string = 'all-files-index'
param chatGptDeploymentName string = 'chat'
param chatGptModelName string = 'gpt-35-turbo'
param chatGptDeploymentCapacity int = 30
param chunkTargetSize string = '750'
param targetPages string = 'ALL'
param formRecognizerApiVersion string = '2022-08-31'
param pdfSubmitQueue string = 'pdf-submit-queue'
param pdfPollingQueue string = 'pdf-polling-queue'
param nonPdfSubmitQueue string = 'non-pdf-submit-queue'
param mediaSubmitQueue string = 'media-submit-queue'
param textEnrichmentQueue string = 'text-enrichment-queue'
param queryTermLanguage string = 'English'
param maxSecondsHideOnUpload string = '300'
param maxSubmitRequeueCount string = '10'
param pollQueueSubmitBackoff string = '60'
param pdfSubmitQueueBackoff string = '60'
param maxPollingRequeueCount string = '10'
param submitRequeueHideSeconds  string = '1200'
param pollingBackoff string = '30'
param maxReadAttempts string = '5'
param cuaEnabled bool = false
param cuaId string = ''
param maxEnrichmentRequeueCount string = '10'
param enrichmentBackoff string = '60'
param targetTranslationLanguage string = 'en'
param enableDevCode bool = false




@description('Id of the user or app to assign application roles')
param principalId string = ''

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
      name: 'B2'
      capacity: 3
    }
    kind: 'linux'
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
    appSettings: {
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_KEY: storage.outputs.key
      AZURE_OPENAI_SERVICE: azureOpenAIServiceName //cognitiveServices.outputs.name
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchServices.outputs.name
      AZURE_SEARCH_SERVICE_KEY: searchServices.outputs.searchServiceKey
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: !empty(chatGptDeploymentName) ? chatGptDeploymentName : chatGptModelName
      AZURE_OPENAI_SERVICE_KEY: azureOpenAIServiceKey
      APPINSIGHTS_INSTRUMENTATIONKEY: logging.outputs.applicationInsightsInstrumentationKey
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_KEY: cosmosdb.outputs.CosmosDBKey
      COSMOSDB_DATABASE_NAME: cosmosdb.outputs.CosmosDBDatabaseName
      COSMOSDB_CONTAINER_NAME: cosmosdb.outputs.CosmosDBContainerName
      QUERY_TERM_LANGUAGE: queryTermLanguage
    }
    aadClientId: aadClientId
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
        name: !empty(chatGptDeploymentName) ? chatGptDeploymentName : chatGptModelName
        model: {
          format: 'OpenAI'
          name: chatGptModelName
          version: '0301'
        }
        sku: {
          name: 'Standard'
          capacity: chatGptDeploymentCapacity
        }
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
  }
}

module enrichment 'core/ai/enrichment.bicep' = {
  scope: rg
  name: 'enrichment'
  params: {
    name: !empty(enrichmentName) ? enrichmentName : '${prefix}-enrichment-${abbrs.cognitiveServicesAccounts}${randomString}'
    location: location
    tags: tags
    sku: encichmentSkuName
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
    databaseName: 'statusdb'
    containerName: 'statuscontainer'
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
    appServicePlanId: appServicePlan.outputs.id
    runtime: 'python'
    appInsightsConnectionString: logging.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: logging.outputs.applicationInsightsInstrumentationKey
    blobStorageAccountKey: storage.outputs.key
    blobStorageAccountName: storage.outputs.name
    blobStorageAccountConnectionString: storage.outputs.connectionString
    blobStorageAccountOutputContainerName: containerName
    blobStorageAccountUploadContainerName: uploadContainerName
    blobStorageAccountLogContainerName: functionLogsContainerName
    formRecognizerEndpoint: formrecognizer.outputs.formRecognizerAccountEndpoint
    formRecognizerApiKey: formrecognizer.outputs.formRecognizerAccountKey
    CosmosDBEndpointURL: cosmosdb.outputs.CosmosDBEndpointURL
    CosmosDBKey: cosmosdb.outputs.CosmosDBKey
    CosmosDBDatabaseName: cosmosdb.outputs.CosmosDBDatabaseName
    CosmosDBContainerName: cosmosdb.outputs.CosmosDBContainerName
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
    maxPollingRequeueCount: maxPollingRequeueCount
    submitRequeueHideSeconds: submitRequeueHideSeconds
    pollingBackoff: pollingBackoff
    maxReadAttempts: maxReadAttempts
    enrichmentKey: enrichment.outputs.cognitiveServiceAccountKey
    enrichmentEndpoint: enrichment.outputs.cognitiveServiceEndpoint
    enrichmentName: enrichment.outputs.cognitiveServicerAccountName
    targetTranslationLanguage: targetTranslationLanguage
    maxEnrichmentRequeueCount: maxEnrichmentRequeueCount
    enrichmentBackoff: enrichmentBackoff
    enableDevCode: enableDevCode
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
output AZURE_SEARCH_KEY string = searchServices.outputs.searchServiceKey
output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_CONTAINER string = containerName
output AZURE_STORAGE_KEY string = storage.outputs.key
output BACKEND_URI string = backend.outputs.uri
output BACKEND_NAME string = backend.outputs.name
output RESOURCE_GROUP_NAME string = rg.name
output AZURE_OPENAI_CHAT_GPT_DEPLOYMENT string = !empty(chatGptDeploymentName) ? chatGptDeploymentName : chatGptModelName
output AZURE_OPENAI_SERVICE_KEY string = azureOpenAIServiceKey
#disable-next-line outputs-should-not-contain-secrets
output COG_SERVICES_FOR_SEARCH_KEY string = searchServices.outputs.cogServiceKey
output AZURE_FUNCTION_APP_NAME string = functions.outputs.name
output AZURE_COSMOSDB_URL string = cosmosdb.outputs.CosmosDBEndpointURL
output AZURE_COSMOSDB_KEY string = cosmosdb.outputs.CosmosDBKey
output AZURE_COSMOSDB_DATABASE_NAME string = cosmosdb.outputs.CosmosDBDatabaseName
output AZURE_COSMOSDB_CONTAINER_NAME string = cosmosdb.outputs.CosmosDBContainerName
output AZURE_FORM_RECOGNIZER_ENDPOINT string = formrecognizer.outputs.formRecognizerAccountEndpoint
output AZURE_FORM_RECOGNIZER_KEY string = formrecognizer.outputs.formRecognizerAccountKey
output AZURE_BLOB_DROP_STORAGE_CONTAINER string = uploadContainerName
output AZURE_BLOB_LOG_STORAGE_CONTAINER string = functionLogsContainerName
output CHUNK_TARGET_SIZE string = chunkTargetSize
output FR_API_VERSION string = formRecognizerApiVersion
output TARGET_PAGES string = targetPages
output BLOB_CONNECTION_STRING string = storage.outputs.connectionString
output AzureWebJobsStorage string = storage.outputs.connectionString
output PDFSUBMITQUEUE string = pdfSubmitQueue
output PDFPOLLINGQUEUE string = pdfPollingQueue
output NONPDFSUBMITQUEUE string = nonPdfSubmitQueue
output MEDIASUBMITQUEUE string = mediaSubmitQueue
output TEXTENRICHMENTQUEUE string = textEnrichmentQueue
output MAX_SECONDS_HIDE_ON_UPLOAD string = maxSecondsHideOnUpload
output MAX_SUBMIT_REQUEUE_COUNT string = maxSubmitRequeueCount
output POLL_QUEUE_SUBMIT_BACKOFF string = pollQueueSubmitBackoff
output PDF_SUBMIT_QUEUE_BACKOFF string = pdfSubmitQueueBackoff
output MAX_POLLING_REQUEUE_COUNT string = maxPollingRequeueCount 
output SUBMIT_REQUEUE_HIDE_SECONDS string = submitRequeueHideSeconds
output POLLING_BACKOFF string = pollingBackoff
output MAX_READ_ATTEMPTS string = maxReadAttempts 
output ENRICHMENT_KEY string = enrichment.outputs.cognitiveServiceAccountKey
output ENRICHMENT_ENDPOINT string = enrichment.outputs.cognitiveServiceEndpoint
output ENRICHMENT_NAME string = enrichment.outputs.cognitiveServicerAccountName
output TARGET_TRANSLATION_LANGUAGE string = targetTranslationLanguage
output MAX_ENRICHMENT_REQUEUE_COUNT string = maxEnrichmentRequeueCount
output ENRICHMENT_BACKOFF string = enrichmentBackoff
output ENABLE_DEV_CODE bool = enableDevCode
