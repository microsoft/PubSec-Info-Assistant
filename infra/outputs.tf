output "STREAMLIT_HOST_URI" {
  value = "https://${local.backend_name}.${var.azure_websites_domain}"
}

output "AZURE_LOCATION" {
  value = var.location
}

output "AZURE_OPENAI_SERVICE" {
  value = var.useExistingAOAIService ? var.azureOpenAIServiceName : module.openaiServices.name
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
  value = var.contentContainerName
}

output "AZURE_STORAGE_UPLOAD_CONTAINER" {
  value = var.uploadContainerName
}

output "BACKEND_URI" {
  value = module.backend.uri
}

output "BACKEND_NAME" {
  value = module.backend.web_app_name 
}

output "RESOURCE_GROUP_NAME" {
  value = azurerm_resource_group.rg.name
}

output "AZURE_OPENAI_CHAT_GPT_DEPLOYMENT" {
  value = var.chatGptDeploymentName != "" ? var.chatGptDeploymentName : var.chatGptModelName != "" ? var.chatGptModelName : "gpt-35-turbo-16k"
}

output "AZURE_OPENAI_RESOURCE_GROUP" {
  value = var.useExistingAOAIService ? var.azureOpenAIResourceGroup : azurerm_resource_group.rg.name
}

output "AZURE_FUNCTION_APP_NAME" {
  value = module.functions.function_app_name
}

output "AZURE_COSMOSDB_URL" {
  value = module.cosmosdb.CosmosDBEndpointURL
}

output "AZURE_COSMOSDB_LOG_DATABASE_NAME" {
  value = module.cosmosdb.CosmosDBLogDatabaseName
}

output "AZURE_COSMOSDB_LOG_CONTAINER_NAME" {
  value = module.cosmosdb.CosmosDBLogContainerName
}

output "AZURE_FORM_RECOGNIZER_ENDPOINT" {
  value = module.formrecognizer.formRecognizerAccountEndpoint
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

output "ENRICHMENT_ENDPOINT" {
  value = module.cognitiveServices.cognitiveServiceEndpoint
}

output "ENRICHMENT_NAME" {
  value = module.cognitiveServices.cognitiveServicerAccountName
}

output "TARGET_TRANSLATION_LANGUAGE" {
  value = var.targetTranslationLanguage
}

output "ENABLE_DEV_CODE" {
  value = var.enableDevCode
}

output "AZURE_SUBSCRIPTION_ID" {
  value = var.subscriptionId
}

output "BLOB_STORAGE_ACCOUNT_ENDPOINT" {
  value = module.storage.primary_endpoints
}

output "EMBEDDING_VECTOR_SIZE" {
  value = var.useAzureOpenAIEmbeddings ? "1536" : var.sentenceTransformerEmbeddingVectorSize
}

output "TARGET_EMBEDDINGS_MODEL" {
  value = var.useAzureOpenAIEmbeddings ? "azure-openai_${var.azureOpenAIEmbeddingDeploymentName}" : var.sentenceTransformersModelName
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

output "ENRICHMENT_APPSERVICE_NAME" {
  value = module.enrichmentApp.name
}

output "ENRICHMENT_APPSERVICE_URL" {
  value = module.enrichmentApp.uri
}

output "DEPLOYMENT_KEYVAULT_NAME" {
  value = module.kvModule.keyVaultName
}

output "CHAT_WARNING_BANNER_TEXT" {
  value = var.chatWarningBannerText
}

output "AZURE_OPENAI_ENDPOINT"  {
  value = var.useExistingAOAIService ? "https://${var.azureOpenAIServiceName}.openai.azure.com/" : module.openaiServices.endpoint
}

output "AZURE_ENVIRONMENT" {
  value = var.azure_environment
}

output "BING_SEARCH_ENDPOINT" {
  value = var.enableWebChat ? module.bingSearch[0].endpoint : ""
}

output "BING_SEARCH_KEY" {
  value = var.enableWebChat ? module.bingSearch[0].key : ""
}

output "ENABLE_BING_SAFE_SEARCH" {
  value = var.enableBingSafeSearch
}

output "AZURE_AI_TRANSLATION_DOMAIN" {
  value = var.azure_ai_translation_domain
}

output "AZURE_AI_TEXT_ANALYTICS_DOMAIN" {
  value = var.azure_ai_text_analytics_domain
}

output "AZURE_ARM_MANAGEMENT_API" {
  value = var.azure_arm_management_api
}