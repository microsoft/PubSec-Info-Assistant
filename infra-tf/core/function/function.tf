data "azurerm_key_vault" "existing_kv" {
  name                = var.keyVaultName
  resource_group_name = var.resourceGroupName
}

data "azurerm_storage_account" "existing_sa" {
  name                = var.blobStorageAccountName
  resource_group_name = var.resourceGroupName
}

// Create function app resource
resource "azurerm_linux_function_app" "function_app" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resourceGroupName
  service_plan_id           = var.appServicePlanId
  storage_account_name      = var.blobStorageAccountName
  storage_account_access_key= "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-BLOB-STORAGE-KEY)"
  https_only                = true

  site_config {
    application_stack {
      python_version = "3.10"
    }
    always_on        = true
    http2_enabled    = true
  }

  connection_string {
    name  = "BLOB_CONNECTION_STRING"
    type  = "Custom"
    value = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BLOB-CONNECTION-STRING)"
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD              = "true"
    AzureWebJobsStorage = "DefaultEndpointsProtocol=https;AccountName=${var.blobStorageAccountName};EndpointSuffix=${var.endpointSuffix};AccountKey=${data.azurerm_storage_account.existing_sa.primary_access_key}"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${var.blobStorageAccountName};EndpointSuffix=${var.endpointSuffix};AccountKey=${data.azurerm_storage_account.existing_sa.primary_access_key}"
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
    AZURE_BLOB_STORAGE_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-BLOB-STORAGE-KEY)"
    CHUNK_TARGET_SIZE = var.chunkTargetSize
    TARGET_PAGES = var.targetPages
    FR_API_VERSION = var.formRecognizerApiVersion
    AZURE_FORM_RECOGNIZER_ENDPOINT = var.formRecognizerEndpoint
    AZURE_FORM_RECOGNIZER_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-FORM-RECOGNIZER-KEY)"
    BLOB_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BLOB-CONNECTION-STRING)"
    COSMOSDB_URL = var.CosmosDBEndpointURL
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
    ENRICHMENT_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/ENRICHMENT-KEY)"
    ENRICHMENT_ENDPOINT = var.enrichmentEndpoint
    ENRICHMENT_NAME = var.enrichmentName
    ENRICHMENT_LOCATION = var.enrichmentLocation
    TARGET_TRANSLATION_LANGUAGE = var.targetTranslationLanguage
    MAX_ENRICHMENT_REQUEUE_COUNT = var.maxEnrichmentRequeueCount
    ENRICHMENT_BACKOFF = var.enrichmentBackoff
    ENABLE_DEV_CODE = tostring(var.enableDevCode)
    EMBEDDINGS_QUEUE = var.EMBEDDINGS_QUEUE
    AZURE_SEARCH_SERVICE_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-SEARCH-SERVICE-KEY)"
    COSMOSDB_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/COSMOSDB-KEY)"
    AZURE_SEARCH_SERVICE_ENDPOINT = var.azureSearchServiceEndpoint
    AZURE_SEARCH_INDEX = var.azureSearchIndex
  }

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = data.azurerm_key_vault.existing_kv.id

  tenant_id = azurerm_linux_function_app.function_app.identity.0.tenant_id
  object_id = azurerm_linux_function_app.function_app.identity.0.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "function_app_identity_principal_id" {
  value = azurerm_linux_function_app.function_app.identity.0.principal_id
}
