# Terraform resource file to create a service plan for the function app
resource "azurerm_service_plan" "funcServicePlan" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resourceGroupName
  sku_name = var.sku["size"]
  worker_count = var.sku["capacity"]
  os_type = "Linux"

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "scaleout" {
  name                = azurerm_service_plan.funcServicePlan.name
  resource_group_name = var.resourceGroupName
  location            = var.location
  target_resource_id  = azurerm_service_plan.funcServicePlan.id

  profile {
    name = "Scale out condition"
    capacity {
      default = 1
      minimum = 1
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.funcServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "GreaterThan"
        threshold           = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.funcServicePlan.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "LessThan"
        threshold           = 40
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT2M"
      }
    }
  }
}



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
  service_plan_id           = azurerm_service_plan.funcServicePlan.id
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
    BINGSEARCH_KEY = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/BINGSEARCH-KEY)"
    AZURE_SEARCH_SERVICE_ENDPOINT = var.azureSearchServiceEndpoint
    AZURE_SEARCH_INDEX = var.azureSearchIndex
    AZURE_AI_TRANSLATION_DOMAIN = var.azure_ai_translation_domain
    AZURE_AI_TEXT_ANALYTICS_DOMAIN = var.azure_ai_text_analytics_domain
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


# output "id" {
#   value = azurerm_service_plan.funcServicePlan.id
# }

output "name" {
  value = azurerm_service_plan.funcServicePlan.name
}
