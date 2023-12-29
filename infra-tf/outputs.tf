
output "AZURE_LOCATION" {
  value = var.location
}

output "AZURE_OPENAI_SERVICE" {
  value = var.azureOpenAIServiceName
}

output "AZURE_SEARCH_INDEX" {
  value = var.searchIndexName
}

output "AZURE_SEARCH_SERVICE" {
  value = module.searchServices.name
}

output "AZURE_SEARCH_SERVICE_ENDPOINT" {
  value = module.searchServices.endpoint
}

output "AZURE_STORAGE_ACCOUNT" {
  value = module.storage.name
}

output "AZURE_STORAGE_ACCOUNT_ENDPOINT" {
  value = module.storage.primary_endpoints
}

output "AZURE_STORAGE_CONTAINER" {
  value = var.containerName
}

output "AZURE_STORAGE_UPLOAD_CONTAINER" {
  value = var.uploadContainerName
}

# output "BACKEND_URI" {
#   value = azurerm_app_service.example.site_credential[0].default_site_hostname
# }

# output "BACKEND_NAME" {
#   value = azurerm_app_service.example.name
# }

output "RESOURCE_GROUP_NAME" {
  value = azurerm_resource_group.rg.name
}

output "AZURE_OPENAI_CHAT_GPT_DEPLOYMENT" {
  value = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k"
}

output "AZURE_OPENAI_RESOURCE_GROUP" {
  value = var.azureOpenAIResourceGroup
}

# output "AZURE_FUNCTION_APP_NAME" {
#   value = azurerm_function_app.example.name
# }

output "AZURE_COSMOSDB_URL" {
  value = module.cosmosdb.CosmosDBEndpointURL
}

output "AZURE_COSMOSDB_LOG_DATABASE_NAME" {
  value = module.cosmosdb.CosmosDBLogDatabaseName
}

output "AZURE_COSMOSDB_LOG_CONTAINER_NAME" {
  value = module.cosmosdb.CosmosDBLogContainerName
}

output "AZURE_COSMOSDB_TAGS_DATABASE_NAME" {
  value = module.cosmosdb.CosmosDBTagsDatabaseName
}

output "AZURE_COSMOSDB_TAGS_CONTAINER_NAME" {
  value = module.cosmosdb.CosmosDBTagsContainerName
}

output "AZURE_FORM_RECOGNIZER_ENDPOINT" {
  value = length(module.cognitiveServices) > 0 ? module.cognitiveServices[0].endpoint : null
}

output "AZURE_BLOB_DROP_STORAGE_CONTAINER" {
  value = var.uploadContainerName
}

output "AZURE_BLOB_LOG_STORAGE_CONTAINER" {
  value = var.functionLogsContainerName
}

output "CHUNK_TARGET_SIZE" {
  value = var.chunkTargetSize
}

output "FR_API_VERSION" {
  value = var.formRecognizerApiVersion
}

output "TARGET_PAGES" {
  value = var.targetPages
}

output "AzureWebJobsStorage" {
  sensitive = true
  value = module.storage.connection_string
}

output "ENRICHMENT_ENDPOINT" {
  value = length(module.cognitiveServices) > 0 ? module.cognitiveServices[0].endpoint : null
}

output "ENRICHMENT_NAME" {
  value = length(module.cognitiveServices) > 0 ? module.cognitiveServices[0].name : null
}

output "TARGET_TRANSLATION_LANGUAGE" {
  value = var.targetTranslationLanguage
}

output "ENABLE_DEV_CODE" {
  value = var.enableDevCode
}

output "AZURE_CLIENT_ID" {
  value = var.aadMgmtClientId
}

output "AZURE_TENANT_ID" {
  value = var.tenantId
}

output "AZURE_SUBSCRIPTION_ID" {
  value = var.subscriptionId
}

output "IS_USGOV_DEPLOYMENT" {
  value = var.isGovCloudDeployment
}

output "BLOB_STORAGE_ACCOUNT_ENDPOINT" {
  value = module.storage.primary_endpoints
}

output "EMBEDDING_VECTOR_SIZE" {
  value = var.useAzureOpenAIEmbeddings ? "1536" : var.sentenceTransformerEmbeddingVectorSize
}

output "TARGET_EMBEDDINGS_MODEL" {
  value = var.useAzureOpenAIEmbeddings ? "${local.abbrs["openAIEmbeddingModel"]}${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
}

output "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME" {
  value = var.azureOpenAIEmbeddingDeploymentName
}

output "USE_AZURE_OPENAI_EMBEDDINGS" {
  value = var.useAzureOpenAIEmbeddings
}

output "EMBEDDING_DEPLOYMENT_NAME" {
  value = var.useAzureOpenAIEmbeddings ? var.azureOpenAIEmbeddingDeploymentName : var.sentenceTransformersModelName
}

# output "ENRICHMENT_APPSERVICE_NAME" {
#   value = azurerm_app_service.example.name
# }

output "DEPLOYMENT_KEYVAULT_NAME" {
  value = module.kvModule.keyVaultName
}