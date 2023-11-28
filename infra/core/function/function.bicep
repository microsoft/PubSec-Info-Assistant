@description('Name of the function app')
param name string

@description('Id of the function app hosting plan')
param appServicePlanId string

@description('Location of the function app')
param location string = resourceGroup().location

@description('Tags for the function app')
param tags object = {}

@description('Runtime of the function app')
param runtime string = 'python'

@description('Application Insights Instrumentation Key')
@secure()
param appInsightsInstrumentationKey string

@description('Application Insights Connection String')
@secure()
param appInsightsConnectionString string

@description('Azure Blob Storage Account Name')
param blobStorageAccountName string

@description('Azure Blob Storage Account Endpoint')
param blobStorageAccountEndpoint string

@description('Azure Blob Storage Account Upload Container Name')
param blobStorageAccountUploadContainerName string

@description('Azure Blob Storage Account Output Container Name')
param blobStorageAccountOutputContainerName string

@description('Azure Blob Storage Account Log Container Name')
param blobStorageAccountLogContainerName string

@description('Azure Blob Storage Account Key')
@secure()
param blobStorageAccountKey string

@description('Azure Blob Storage Account Connection String')
@secure()
param blobStorageAccountConnectionString string

@description('Chunk Target Size ')
param chunkTargetSize string

@description('Target Pages')
param targetPages string

@description('Form Recognizer API Version')
param formRecognizerApiVersion string

@description('Form Recognizer Endpoint')
param formRecognizerEndpoint string

@description('Form Recognizer API Key')
@secure()
param formRecognizerApiKey string

@description('CosmosDB Endpoint')
param CosmosDBEndpointURL string

@description('CosmosDB Key')
@secure()
param CosmosDBKey string

@description('CosmosDB Log Database Name')
param CosmosDBLogDatabaseName string

@description('CosmosDB Log Container Name')
param CosmosDBLogContainerName string

@description('CosmosDB Tags Database Name')
param CosmosDBTagsDatabaseName string

@description('CosmosDB Tags Container Name')
param CosmosDBTagsContainerName string

@description('Name of the submit queue for PDF files')
param pdfSubmitQueue string

@description('Name of the queue used to poll for completed FR processing')
param pdfPollingQueue string

@description('The queue which is used to trigger processing of non-PDF files')
param nonPdfSubmitQueue string

@description('The queue which is used to trigger processing of media files')
param mediaSubmitQueue string

@description('The queue which is used to trigger processing of text files')
param textEnrichmentQueue string

@description('The queue which is used to trigger processing of image files')
param imageEnrichmentQueue string

@description('The maximum number of seconds  between uploading a file and submitting it to FR')
param maxSecondsHideOnUpload string

@description('The maximum number of times a file can be resubmitted to FR due to throttling or internal FR capacity limitations')
param maxSubmitRequeueCount string

@description('the number of seconds that a message sleeps before we try to poll for FR completion')
param pollQueueSubmitBackoff string

@description('The number of seconds a message sleeps before trying to resubmit due to throttling request from FR')
param pdfSubmitQueueBackoff string

@description('Max times we will retry the submission due to throttling or internal errors in FR')
param maxPollingRequeueCount string

@description('Number of seconds to delay before trying to resubmit a doc to FR when it reported an internal error')
param submitRequeueHideSeconds string

@description('The number of seconds we will hide a message before trying to repoll due to FR still processing a file. This is the default value that escalates exponentially')
param pollingBackoff string

@description('The maximum number of times we will retry to read a full processed document from FR. Failures in read may be due to network issues downloading the large response')
param maxReadAttempts string

@description('Key to access the enrichment service')
param enrichmentKey string

@description('Endpoint of the enrichment service')
param enrichmentEndpoint string

@description('Name of the enrichment service')
param enrichmentName string

@description('Location of the enrichment service')
param enrichmentLocation string

@description('Target language to translate content to')
param targetTranslationLanguage string

@description('Max times we will retry the enriichment due to throttling or internal errors')
param maxEnrichmentRequeueCount string

@description('The number of seconds we will hide a message before trying to call enrichment service throttling. This is the default value that escalates exponentially')
param enrichmentBackoff string

@description('A boolean value that flags if a user wishes to enable or disable code under development')
param enableDevCode bool

@description('A boolean value that flags if a user wishes to enable or disable code under development')
param EMBEDDINGS_QUEUE string

@description('Name of the Azure Search Service index to post data to for ingestion')
param azureSearchIndex string

@description('Endpoint of the Azure Search Service to post data to for ingestion')
param azureSearchServiceEndpoint string

@description('Used to connect and authenticate to Azure Search Service')
param azureSearchServiceKey string

// Create function app resource
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    serverFarmId: appServicePlanId
    siteConfig: {
      http20Enabled: true
      linuxFxVersion: 'python|3.10'
      alwaysOn: true
      minTlsVersion: '1.2'
      connectionStrings: [
        {
          name: 'BLOB_CONNECTION_STRING'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${blobStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${blobStorageAccountKey}'
        }
      ]
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${blobStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${blobStorageAccountKey}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${blobStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${blobStorageAccountKey}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(name)
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT'
          value: blobStorageAccountName
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT_ENDPOINT'
          value: blobStorageAccountEndpoint
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME'
          value: blobStorageAccountUploadContainerName
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME'
          value: blobStorageAccountOutputContainerName
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME'
          value: blobStorageAccountLogContainerName
        }
        {
          name: 'AZURE_BLOB_STORAGE_KEY'
          value: blobStorageAccountKey
        }
        {
          name: 'CHUNK_TARGET_SIZE'
          value: chunkTargetSize
        }
        {
          name: 'TARGET_PAGES'
          value: targetPages
        }
        {
          name: 'FR_API_VERSION'
          value: formRecognizerApiVersion
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: formRecognizerEndpoint
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: formRecognizerApiKey
        }
        {
          name: 'BLOB_CONNECTION_STRING'
          value: blobStorageAccountConnectionString
        }
        {
          name: 'COSMOSDB_URL'
          value: CosmosDBEndpointURL
        }
        {
          name: 'COSMOSDB_KEY'
          value: CosmosDBKey
        }
        {
          name: 'COSMOSDB_LOG_DATABASE_NAME'
          value: CosmosDBLogDatabaseName
        }
        {
          name: 'COSMOSDB_LOG_CONTAINER_NAME'
          value: CosmosDBLogContainerName
        }
        {
          name: 'COSMOSDB_TAGS_DATABASE_NAME'
          value: CosmosDBTagsDatabaseName
        }
        {
          name: 'COSMOSDB_TAGS_CONTAINER_NAME'
          value: CosmosDBTagsContainerName
        }
        {
          name: 'PDF_SUBMIT_QUEUE'
          value: pdfSubmitQueue
        }
        {
          name: 'PDF_POLLING_QUEUE'
          value: pdfPollingQueue
        }
        {
          name: 'NON_PDF_SUBMIT_QUEUE'
          value: nonPdfSubmitQueue
        }
        {
          name: 'MEDIA_SUBMIT_QUEUE'
          value: mediaSubmitQueue
        }
        {
          name: 'TEXT_ENRICHMENT_QUEUE'
          value: textEnrichmentQueue
        }
        {
          name: 'IMAGE_ENRICHMENT_QUEUE'
          value: imageEnrichmentQueue
        }
        {
          name: 'MAX_SECONDS_HIDE_ON_UPLOAD'
          value: maxSecondsHideOnUpload
        }
        {
          name: 'MAX_SUBMIT_REQUEUE_COUNT'
          value: maxSubmitRequeueCount
        }
        {
          name: 'POLL_QUEUE_SUBMIT_BACKOFF'
          value: pollQueueSubmitBackoff
        }
        {
          name: 'PDF_SUBMIT_QUEUE_BACKOFF'
          value: pdfSubmitQueueBackoff
        }
        {
          name: 'MAX_POLLING_REQUEUE_COUNT'
          value: maxPollingRequeueCount
        }
        {
          name: 'SUBMIT_REQUEUE_HIDE_SECONDS'
          value: submitRequeueHideSeconds
        }
        {
          name: 'POLLING_BACKOFF'
          value: pollingBackoff
        }
        {
          name: 'MAX_READ_ATTEMPTS'
          value: maxReadAttempts
        }
        {
          name: 'ENRICHMENT_KEY'
          value: enrichmentKey
        }
        {
          name: 'ENRICHMENT_ENDPOINT'
          value: enrichmentEndpoint
        }
        {
          name: 'ENRICHMENT_NAME'
          value: enrichmentName
        }
        {
          name: 'ENRICHMENT_LOCATION'
          value: enrichmentLocation
        }
        {
          name: 'TARGET_TRANSLATION_LANGUAGE'
          value: targetTranslationLanguage
        }
        {
          name: 'MAX_ENRICHMENT_REQUEUE_COUNT'
          value: maxEnrichmentRequeueCount
        }
        {
          name: 'ENRICHMENT_BACKOFF'
          value: enrichmentBackoff
        }
        {
          name: 'ENABLE_DEV_CODE'
          value: string(enableDevCode)
        }        
        {
          name: 'EMBEDDINGS_QUEUE'
          value: EMBEDDINGS_QUEUE
        }
        {
          name: 'AZURE_SEARCH_SERVICE_KEY'
          value: azureSearchServiceKey 
        }  
        {
          name: 'AZURE_SEARCH_SERVICE_ENDPOINT'
          value: azureSearchServiceEndpoint
        }  
        {
          name: 'AZURE_SEARCH_INDEX'
          value: azureSearchIndex
        }                  

      ]
    }
  }
}

output name string = functionApp.name
output identityPrincipalId string = functionApp.identity.principalId
