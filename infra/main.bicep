targetScope = 'resourceGroup'

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
param aadMgmtUrl string = ''
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
param cosmosdbName string = ''
param formRecognizerName string = ''
param enrichmentName string = ''
param formRecognizerSkuName string = 'S0'
param enrichmentSkuName string = 'S0'
param appServicePlanName string = ''
param enrichmentAppServicePlanName string = ''
param resourceGroupName string = 'rg-hmcts-powerplatform_270324'
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param backendServiceName string = ''
param enrichmentServiceName string = ''
param functionsAppName string = ''
param searchServicesName string = ''
param searchServicesSkuName string = 'basic'
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
param formRecognizerApiVersion string = '2023-07-31'
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
//var tags = { ProjectName: 'Information Assistant', BuildNumber: buildNumber }
var tags = { Application: 'Knowledge Management Assistant', Owner: 'Nitesh Soni' }
var prefix = 'infoasst'

// Organize resources in a resource group
//resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//  name: !empty(resourceGroupName) ? resourceGroupName : '${prefix}-${environmentName}'
//  location: location
//  tags: tags
//}

module logging 'core/logging/logging.bicep' = {
  name: 'logging'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
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
  //scope: rg
  scope: resourceGroup(resourceGroupName)
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

// Create an App Service Plan for functions
module funcServicePlan 'core/host/funcserviceplan.bicep' = {
  name: 'funcserviceplan'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${prefix}-${abbrs.funcServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'B2'
      capacity: 2
    }
    kind: 'linux'
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module enrichmentAppServicePlan 'core/host/enrichmentappserviceplan.bicep' = {
  name: 'enrichmentAppserviceplan'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(enrichmentAppServicePlanName) ? enrichmentAppServicePlanName : '${prefix}-enrichment${abbrs.webServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'B2'
      // tier: 'Basic'
      // size: 'B1'
      // family: 'B'
      capacity: 3
    }
    kind: 'linux'
    //reserved: true
  }
}

// Create an App Service Plan and supporting services for the enrichment app service
module enrichmentApp 'core/host/enrichmentappservice.bicep' = {
  name: 'enrichmentApp'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
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
    keyVaultName: kvModule.outputs.keyVaultName
    appSettings: {
      EMBEDDINGS_QUEUE: embeddingsQueue
      LOG_LEVEL: 'DEBUG'
      DEQUEUE_MESSAGE_BATCH_SIZE: 3
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_UPLOAD_CONTAINER: uploadContainerName
      AZURE_BLOB_STORAGE_ENDPOINT: storage.outputs.primaryEndpoints.blob
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_LOG_DATABASE_NAME: cosmosdb.outputs.CosmosDBLogDatabaseName
      COSMOSDB_LOG_CONTAINER_NAME: cosmosdb.outputs.CosmosDBLogContainerName
      COSMOSDB_TAGS_DATABASE_NAME: cosmosdb.outputs.CosmosDBTagsDatabaseName
      COSMOSDB_TAGS_CONTAINER_NAME: cosmosdb.outputs.CosmosDBTagsContainerName
      MAX_EMBEDDING_REQUEUE_COUNT: 5
      EMBEDDING_REQUEUE_BACKOFF: 60
      AZURE_OPENAI_SERVICE: useExistingAOAIService ? azureOpenAIServiceName : cognitiveServices.outputs.name
      AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME: azureOpenAIEmbeddingDeploymentName
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchServices.outputs.name
      TARGET_EMBEDDINGS_MODEL: useAzureOpenAIEmbeddings ? '${abbrs.openAIEmbeddingModel}${azureOpenAIEmbeddingDeploymentName}' : sentenceTransformersModelName
      EMBEDDING_VECTOR_SIZE: useAzureOpenAIEmbeddings ? 1536 : sentenceTransformerEmbeddingVectorSize
      AZURE_SEARCH_SERVICE_ENDPOINT: searchServices.outputs.endpoint
      WEBSITES_CONTAINER_START_TIME_LIMIT: 600
      IS_GOV_CLOUD_DEPLOYMENT: isGovCloudDeployment
    }
  }
  dependsOn: [
    kvModule
  ]
}

// The application frontend
module backend 'core/host/appservice.bicep' = {
  name: 'web'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
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
    keyVaultName: kvModule.outputs.keyVaultName
    appSettings: {
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_ENDPOINT: storage.outputs.primaryEndpoints.blob
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_UPLOAD_CONTAINER: uploadContainerName
      AZURE_OPENAI_SERVICE: useExistingAOAIService ? azureOpenAIServiceName : cognitiveServices.outputs.name
      AZURE_OPENAI_RESOURCE_GROUP: useExistingAOAIService ? azureOpenAIResourceGroup : resourceGroupName //rg.name
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchServices.outputs.name
      AZURE_SEARCH_SERVICE_ENDPOINT: searchServices.outputs.endpoint
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: !empty(chatGptDeploymentName) ? chatGptDeploymentName : !empty(chatGptModelName) ? chatGptModelName : 'gpt-35-turbo-16k'
      AZURE_OPENAI_CHATGPT_MODEL_NAME: chatGptModelName
      AZURE_OPENAI_CHATGPT_MODEL_VERSION: chatGptModelVersion
      USE_AZURE_OPENAI_EMBEDDINGS: useAzureOpenAIEmbeddings
      EMBEDDING_DEPLOYMENT_NAME: useAzureOpenAIEmbeddings ? azureOpenAIEmbeddingDeploymentName : sentenceTransformersModelName
      AZURE_OPENAI_EMBEDDINGS_MODEL_NAME: azureOpenAIEmbeddingsModelName
      AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION: azureOpenAIEmbeddingsModelVersion
      APPINSIGHTS_INSTRUMENTATIONKEY: logging.outputs.applicationInsightsInstrumentationKey
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_LOG_DATABASE_NAME: cosmosdb.outputs.CosmosDBLogDatabaseName
      COSMOSDB_LOG_CONTAINER_NAME: cosmosdb.outputs.CosmosDBLogContainerName
      COSMOSDB_TAGS_DATABASE_NAME: cosmosdb.outputs.CosmosDBTagsDatabaseName
      COSMOSDB_TAGS_CONTAINER_NAME: cosmosdb.outputs.CosmosDBTagsContainerName
      QUERY_TERM_LANGUAGE: queryTermLanguage
      AZURE_CLIENT_ID: aadMgmtClientId
      AZURE_TENANT_ID: tenantId
      AZURE_SUBSCRIPTION_ID: subscriptionId
      IS_GOV_CLOUD_DEPLOYMENT: isGovCloudDeployment
      CHAT_WARNING_BANNER_TEXT: chatWarningBannerText
      TARGET_EMBEDDINGS_MODEL: useAzureOpenAIEmbeddings ? '${abbrs.openAIEmbeddingModel}${azureOpenAIEmbeddingDeploymentName}' : sentenceTransformersModelName
      ENRICHMENT_APPSERVICE_NAME: enrichmentApp.outputs.name
      APPLICATION_TITLE: applicationtitle
      AZURE_MANAGEMENT_URL:aadMgmtUrl
    }
    aadClientId: aadWebClientId
  }
  dependsOn: [
    kvModule
  ]
}

module cognitiveServices 'core/ai/cognitiveservices.bicep' = if (!useExistingAOAIService) {
  name: 'openai'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${prefix}-${abbrs.openAIServices}${randomString}'
    location: location
    tags: tags
    keyVaultName: kvModule.outputs.keyVaultName
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
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'formrecognizer'
  params: {
    name: !empty(formRecognizerName) ? formRecognizerName : '${prefix}-${abbrs.formRecognizer}${randomString}'
    location: location
    tags: tags
    sku: {
      name: formRecognizerSkuName
    }
    isGovCloudDeployment: isGovCloudDeployment
    keyVaultName: kvModule.outputs.keyVaultName
  }
}

module enrichment 'core/ai/enrichment.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'enrichment'
  params: {
    name: !empty(enrichmentName) ? enrichmentName : '${prefix}-enrichment-${abbrs.cognitiveServicesAccounts}${randomString}'
    location: location
    tags: tags
    sku: enrichmentSkuName
    isGovCloudDeployment: isGovCloudDeployment
    keyVaultName: kvModule.outputs.keyVaultName
  }
}

module searchServices 'core/search/search-services.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'search-services'
  params: {
    name: !empty(searchServicesName) ? searchServicesName : '${prefix}-${abbrs.searchSearchServices}${randomString}'
    keyVaultName: kvModule.outputs.keyVaultName
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
    isGovCloudDeployment: isGovCloudDeployment
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${prefix}${abbrs.storageStorageAccounts}${randomString}'
    location: location
    tags: tags
    keyVaultName: kvModule.outputs.keyVaultName
    storeSecretsInKeyVault: true
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
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${prefix}${abbrs.storageStorageAccounts}media${randomString}'
    keyVaultName: kvModule.outputs.keyVaultName
    storeSecretsInKeyVault: false //Not needed for media service
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
  dependsOn: [
    kvModule
  ]
}

module cosmosdb 'core/db/cosmosdb.bicep' = {
  name: 'cosmosdb'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(cosmosdbName) ? cosmosdbName : '${prefix}-${abbrs.cosmosDBAccounts}${randomString}'
    location: location
    tags: tags
    keyVaultName: kvModule.outputs.keyVaultName
    logDatabaseName: 'statusdb'
    logContainerName: 'statuscontainer'
    tagDatabaseName: 'tagdb'
    tagContainerName: 'tagcontainer'
  }
  dependsOn: [
    kvModule
  ]
}


// Function App 
module functions 'core/function/function.bicep' = {
  name: 'functions'
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(functionsAppName) ? functionsAppName : '${prefix}-${abbrs.webSitesFunctions}${randomString}'
    location: location
    tags: tags
    appServicePlanId: funcServicePlan.outputs.id
    runtime: 'python'
    keyVaultName: kvModule.outputs.keyVaultName
    appInsightsConnectionString: logging.outputs.applicationInsightsConnectionString
    appInsightsInstrumentationKey: logging.outputs.applicationInsightsInstrumentationKey
    blobStorageAccountName: storage.outputs.name
    blobStorageAccountEndpoint: storage.outputs.primaryEndpoints.blob
    blobStorageAccountOutputContainerName: containerName
    blobStorageAccountUploadContainerName: uploadContainerName
    blobStorageAccountLogContainerName: functionLogsContainerName
    formRecognizerEndpoint: formrecognizer.outputs.formRecognizerAccountEndpoint
    CosmosDBEndpointURL: cosmosdb.outputs.CosmosDBEndpointURL
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

  }
  dependsOn: [
    appServicePlan
    storage
    cosmosdb
    kvModule
  ]
}

// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module storageRoleUser 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module storageContribRoleUser 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'storage-contribrole-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module searchRoleUser 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

module searchContribRoleUser 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'search-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: isInAutomation ? 'ServicePrincipal' : 'User'
  }
}

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'openai-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module ACRRoleContainerAppService 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'container-webapp-acrpull-role'
  params: {
    principalId: enrichmentApp.outputs.identityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleBackend 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'storage-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module searchRoleBackend 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'search-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleFunc 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'storage-role-Func'
  params: {
    principalId: functions.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module containerRegistryPush 'core/security/role.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'AcrPush'
  params: {
    principalId: aadMgmtServicePrincipalId
    roleDefinitionId: '8311e382-0749-4cb8-b61a-304f252e45ec'
    principalType: 'ServicePrincipal'
  }
}

// MANAGEMENT SERVICE PRINCIPAL
module openAiRoleMgmt 'core/security/role.bicep' = if (!isInAutomation) {
  //scope: resourceGroup(useExistingAOAIService && !isGovCloudDeployment ? azureOpenAIResourceGroup : rg.name)
  scope: resourceGroup(useExistingAOAIService && !isGovCloudDeployment ? azureOpenAIResourceGroup : resourceGroupName)
  name: 'openai-role-mgmt'
  params: {
    principalId: aadMgmtServicePrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module azMonitor 'core/logging/monitor.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'azure-monitor'
  params: {
    location: location
    logWorkbookName: '${prefix}-${abbrs.logWorkbook}${randomString}'
    //componentResource: '/subscriptions/${subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.OperationalInsights/workspaces/${logging.outputs.logAnalyticsName}'
    componentResource: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/${logging.outputs.logAnalyticsName}'
  }
}

module kvModule 'core/security/keyvault.bicep' = {
  //scope: rg
  scope: resourceGroup(resourceGroupName)
  name: 'keyvault-deployment'
  params: {
    name: '${prefix}-${abbrs.keyvault}${randomString}'
    location: location
    kvAccessObjectId: kvAccessObjectId
    openaiServiceKey: azureOpenAIServiceKey
    spClientSecret: aadMgmtClientSecret
    useExistingAOAIService: useExistingAOAIService
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
output RESOURCE_GROUP_NAME string = resourceGroupName //rg.name
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
