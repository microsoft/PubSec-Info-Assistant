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

resource "azurerm_role_assignment" "acr_pull_role" {
  principal_id         = azurerm_linux_function_app.function_app.identity.0.principal_id
  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
}

data "azurerm_key_vault" "existing" {
  name                = var.keyVaultName
  resource_group_name = var.resourceGroupName
}

data "azurerm_storage_account" "existing_sa" {
  name                = var.blobStorageAccountName
  resource_group_name = var.resourceGroupName
}

// Create function app resource
resource "azurerm_linux_function_app" "function_app" {
  name                                = var.name
  location                            = var.location
  resource_group_name                 = var.resourceGroupName
  service_plan_id                     = azurerm_service_plan.funcServicePlan.id
  storage_account_name                = var.blobStorageAccountName
  storage_account_access_key          = data.azurerm_storage_account.existing_sa.primary_access_key
  #storage_uses_managed_identity       = true
  https_only                          = true
  tags                                = var.tags
  public_network_access_enabled       = var.is_secure_mode ? false : true 
  virtual_network_subnet_id           = var.is_secure_mode ? var.subnetIntegration_id : null
  content_share_force_disabled        = true


  site_config {
    application_stack {
      docker {
        image_name                    = "${var.container_registry}/functionapp"
        image_tag                     = "latest"
        registry_url                  = "https://${var.container_registry}"
        registry_username             = var.container_registry_admin_username
        registry_password             = var.container_registry_admin_password
      }
    }
    container_registry_use_managed_identity = true
    always_on                               = true
    http2_enabled                           = true
    ftps_state                              = "Disabled"
    cors {
      allowed_origins                       = concat([var.azure_portal_domain, "https://ms.portal.azure.com"], var.allowedOrigins)
    }
    vnet_route_all_enabled                  = var.is_secure_mode ? true : false
  }

  identity {
    type = "SystemAssigned"
  }
  
  app_settings = {
    # Network realated settings for secure mode
    WEBSITE_PULL_IMAGE_OVER_VNET                = var.is_secure_mode ? "true" : "false"

    SCM_DO_BUILD_DURING_DEPLOYMENT              = "false"
    ENABLE_ORYX_BUILD                           = "false"
    #Set all connections to use Managed Identity instead of connection strings
    AzureWebJobsStorage                        = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-STORAGE-CONNECTION-STRING)"
    # These will need to be enabled one Azure Functions has support for Managed Identity
    #AzureWebJobsStorage__blobServiceUri         = "https://${var.blobStorageAccountName}.blob.${var.endpointSuffix}"
    #AzureWebJobsStorage__queueServiceUri        = "https://${var.blobStorageAccountName}.queue.${var.endpointSuffix}"
    #AzureWebJobsStorage__tableServiceUri        = "https://${var.blobStorageAccountName}.table.${var.endpointSuffix}"
    #AzureWebJobsSecretStorageKeyVaultUri        = data.azurerm_key_vault.existing.vault_uri
    #AzureWebJobsSecretStorageType               = "keyvault"

    AzureStorageConnection1__blobServiceUri         = "https://${var.blobStorageAccountName}.blob.${var.endpointSuffix}"
    AzureStorageConnection1__queueServiceUri        = "https://${var.blobStorageAccountName}.queue.${var.endpointSuffix}"
    AzureStorageConnection1__tableServiceUri        = "https://${var.blobStorageAccountName}.table.${var.endpointSuffix}"
    
    FUNCTIONS_WORKER_RUNTIME                    = var.runtime
    FUNCTIONS_EXTENSION_VERSION                 = "~4"
    WEBSITE_NODE_DEFAULT_VERSION                = "~14"
    APPLICATIONINSIGHTS_CONNECTION_STRING       = var.appInsightsConnectionString
    APPINSIGHTS_INSTRUMENTATIONKEY              = var.appInsightsInstrumentationKey
    # Environment variables used by custom Python code
    BLOB_STORAGE_ACCOUNT                        = var.blobStorageAccountName
    BLOB_STORAGE_ACCOUNT_ENDPOINT               = var.blobStorageAccountEndpoint
    BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME  = var.blobStorageAccountUploadContainerName
    BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME  = var.blobStorageAccountOutputContainerName
    BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME     = var.blobStorageAccountLogContainerName
    AZURE_QUEUE_STORAGE_ENDPOINT                = var.queueStorageAccountEndpoint
    CHUNK_TARGET_SIZE                           = var.chunkTargetSize
    TARGET_PAGES                                = var.targetPages
    FR_API_VERSION                              = var.formRecognizerApiVersion
    AZURE_FORM_RECOGNIZER_ENDPOINT              = var.formRecognizerEndpoint
    COSMOSDB_URL                                = var.CosmosDBEndpointURL
    COSMOSDB_LOG_DATABASE_NAME                  = var.CosmosDBLogDatabaseName
    COSMOSDB_LOG_CONTAINER_NAME                 = var.CosmosDBLogContainerName
    PDF_SUBMIT_QUEUE                            = var.pdfSubmitQueue
    PDF_POLLING_QUEUE                           = var.pdfPollingQueue
    NON_PDF_SUBMIT_QUEUE                        = var.nonPdfSubmitQueue
    MEDIA_SUBMIT_QUEUE                          = var.mediaSubmitQueue
    TEXT_ENRICHMENT_QUEUE                       = var.textEnrichmentQueue
    IMAGE_ENRICHMENT_QUEUE                      = var.imageEnrichmentQueue
    MAX_SECONDS_HIDE_ON_UPLOAD                  = var.maxSecondsHideOnUpload
    MAX_SUBMIT_REQUEUE_COUNT                    = var.maxSubmitRequeueCount
    POLL_QUEUE_SUBMIT_BACKOFF                   = var.pollQueueSubmitBackoff
    PDF_SUBMIT_QUEUE_BACKOFF                    = var.pdfSubmitQueueBackoff
    MAX_POLLING_REQUEUE_COUNT                   = var.maxPollingRequeueCount
    SUBMIT_REQUEUE_HIDE_SECONDS                 = var.submitRequeueHideSeconds
    POLLING_BACKOFF                             = var.pollingBackoff
    MAX_READ_ATTEMPTS                           = var.maxReadAttempts
    AZURE_AI_KEY                                = "@Microsoft.KeyVault(SecretUri=${var.keyVaultUri}secrets/AZURE-AI-KEY)"
    AZURE_AI_ENDPOINT                           = var.enrichmentEndpoint
    ENRICHMENT_NAME                             = var.enrichmentName
    AZURE_AI_LOCATION                           = var.enrichmentLocation
    TARGET_TRANSLATION_LANGUAGE                 = var.targetTranslationLanguage
    MAX_ENRICHMENT_REQUEUE_COUNT                = var.maxEnrichmentRequeueCount
    ENRICHMENT_BACKOFF                          = var.enrichmentBackoff
    ENABLE_DEV_CODE                             = tostring(var.enableDevCode)
    EMBEDDINGS_QUEUE                            = var.EMBEDDINGS_QUEUE
    AZURE_SEARCH_SERVICE_ENDPOINT               = var.azureSearchServiceEndpoint
    AZURE_SEARCH_INDEX                          = var.azureSearchIndex
    AZURE_AI_CREDENTIAL_DOMAIN                  = var.azure_ai_credential_domain
    AZURE_OPENAI_AUTHORITY_HOST                 = var.azure_environment
    LOCAL_DEBUG                                 = "false"
  }
  
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_commercial" {
  count                      = var.azure_environment == "AzureUSGovernment" ? 0 : 1
  name                       = azurerm_linux_function_app.function_app.name
  target_resource_id         = azurerm_linux_function_app.function_app.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log  {
    category = "FunctionAppLogs"
  }

  enabled_log {
    category = "AppServiceAuthenticationLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_logs_usgov" {
  count                      = var.azure_environment == "AzureUSGovernment" ? 1 : 0
  name                       = azurerm_linux_function_app.function_app.name
  target_resource_id         = azurerm_linux_function_app.function_app.id
  log_analytics_workspace_id = var.logAnalyticsWorkspaceResourceId

  enabled_log  {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = data.azurerm_key_vault.existing.id

  tenant_id = azurerm_linux_function_app.function_app.identity.0.tenant_id
  object_id = azurerm_linux_function_app.function_app.identity.0.principal_id


  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

data "azurerm_subnet" "subnet" {
  count                = var.is_secure_mode ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resourceGroupName
}

resource "azurerm_private_endpoint" "privateFunctionEndpoint" {
  count                         = var.is_secure_mode ? 1 : 0
  name                          = "${var.name}-private-endpoint"
  location                      = var.location
  resource_group_name           = var.resourceGroupName
  subnet_id                     = data.azurerm_subnet.subnet[0].id
  tags                          = var.tags
  custom_network_interface_name = "infoasstfuncnic"
   

  private_service_connection {
    name = "functionappprivateendpointconnection"
    private_connection_resource_id = azurerm_linux_function_app.function_app.id
    subresource_names = ["sites"]
    is_manual_connection = false
  }
  
  private_dns_zone_group {
    name                 = "${var.name}PrivateDnsZoneGroup"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}