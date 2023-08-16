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

@description('CosmosDB Database Name')
param CosmosDBDatabaseName string

@description('CosmosDB Container Name')
param CosmosDBContainerName string

@description('')
param pdfSubmitQueue string

@description('')
param pdfPollingQueue string

@description('')
param nonPdfSubmitQueue string

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
      connectionStrings:[
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
          name: 'BLOB_STORAGE_ACCOUNT_KEY'
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
          name: 'COSMOSDB_DATABASE_NAME'
          value: CosmosDBDatabaseName
        }
        {
          name: 'COSMOSDB_CONTAINER_NAME'
          value: CosmosDBContainerName
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
      ]
    }
  }
}

output name string = functionApp.name
output identityPrincipalId string = functionApp.identity.principalId
