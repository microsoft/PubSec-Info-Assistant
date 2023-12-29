

// Create function app resource
resource "azurerm_function_app" "function_app" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resourceGroupName
  app_service_plan_id       = var.appServicePlanId
  storage_account_name      = var.blobStorageAccountName
  storage_account_access_key= var.blobStorageAccountKey
  version                   = "~4"
  os_type                   = "linux"
  https_only                = true

  site_config {
    linux_fx_version = "python|3.10"
    always_on        = true
    http2_enabled    = true
    min_tls_version  = "1.2"
  }

  app_settings = {
    AzureWebJobsStorage = "DefaultEndpointsProtocol=https;AccountName=${var.blobStorageAccountName};EndpointSuffix=${var.endpointSuffix};AccountKey=${var.blobStorageAccountKey}"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${var.blobStorageAccountName};EndpointSuffix=${var.endpointSuffix};AccountKey=${var.blobStorageAccountKey}"
    WEBSITE_CONTENTSHARE = lower(var.name)
    FUNCTIONS_WORKER_RUNTIME = var.runtime
    FUNCTIONS_EXTENSION_VERSION = "~4"
    WEBSITE_NODE_DEFAULT_VERSION = "~14"
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.appInsightsConnectionString
    APPINSIGHTS_INSTRUMENTATIONKEY = var.appInsightsInstrumentationKey
    BLOB_STORAGE_ACCOUNT = var.blobStorageAccountName
    BLOB_STORAGE_ACCOUNT_ENDPOINT = var.blobStorageAccountEndpoint
    BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME = var.blobStorageAccountUploadContainerName
    BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME = var.blobStorageAccountOutputContainerName
    BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME = var.blobStorageAccountLogContainerName
    AZURE_BLOB_STORAGE_KEY = var.blobStorageAccountKey
    CHUNK_TARGET_SIZE = var.chunkTargetSize
    TARGET_PAGES = var.targetPages
    FR_API_VERSION = var.formRecognizerApiVersion
    AZURE_FORM_RECOGNIZER_ENDPOINT = var.formRecognizerEndpoint
    AZURE_FORM_RECOGNIZER_KEY = var.formRecognizerApiKey
    BLOB_CONNECTION_STRING = var.blobStorageAccountConnectionString
    COSMOSDB_URL = var.CosmosDBEndpointURL
    COSMOSDB_KEY = var.CosmosDBKey
    COSMOSDB_LOG_DATABASE_NAME = var.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME = var.CosmosDBLogContainerName
    COSMOSDB_TAGS_DATABASE_NAME = var.CosmosDBTagsDatabaseName
    COSMOSDB_TAGS_CONTAINER_NAME = var.CosmosDBTagsContainerName
    PDF_SUBMIT_QUEUE = var.pdfSubmitQueue
    PDF_POLLING_QUEUE = var.pdfPollingQueue
    NON_PDF_SUBMIT_QUEUE = var.nonPdfSubmitQueue
    MEDIA_SUBMIT_QUEUE = var.mediaSubmitQueue
    TEXT_ENRICHMENT_QUEUE = var.textEnrichmentQueue
    IMAGE_ENRICHMENT_QUEUE = var.imageEnrichmentQueue
    MAX_SECONDS_HIDE_ON_UPLOAD = var.maxSecondsHideOnUpload
    MAX_SUBMIT_REQUEUE_COUNT = var.maxSubmitRequeueCount
    POLL_QUEUE_SUBMIT_BACKOFF = var.pollQueueSubmitBackoff
    PDF_SUBMIT_QUEUE_BACKOFF = var.pdfSubmitQueueBackoff
    MAX_POLLING_REQUEUE_COUNT = var.maxPollingRequeueCount
    SUBMIT_REQUEUE_HIDE_SECONDS = var.submitRequeueHideSeconds
    POLLING_BACKOFF = var.pollingBackoff
    MAX_READ_ATTEMPTS = var.maxReadAttempts
    ENRICHMENT_KEY = var.enrichmentKey
    ENRICHMENT_ENDPOINT = var.enrichmentEndpoint
    ENRICHMENT_NAME = var.enrichmentName
    ENRICHMENT_LOCATION = var.enrichmentLocation
    TARGET_TRANSLATION_LANGUAGE = var.targetTranslationLanguage
    MAX_ENRICHMENT_REQUEUE_COUNT = var.maxEnrichmentRequeueCount
    ENRICHMENT_BACKOFF = var.enrichmentBackoff
    ENABLE_DEV_CODE = tostring(var.enableDevCode)
    EMBEDDINGS_QUEUE = var.EMBEDDINGS_QUEUE
    AZURE_SEARCH_SERVICE_KEY = var.azureSearchServiceKey
    AZURE_SEARCH_SERVICE_ENDPOINT = var.azureSearchServiceEndpoint
    AZURE_SEARCH_INDEX = var.azureSearchIndex
  }

  identity {
    type = "SystemAssigned"
  }
}

output "function_app_name" {
  value = azurerm_function_app.function_app.name
}

output "function_app_identity_principal_id" {
  value = azurerm_function_app.function_app.identity.0.principal_id
}
