
output "AZURE_LOCATION" {
  value = var.location
}

output "AZURE_OPENAI_SERVICE" {
  value = module.openaiServices.name
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

output "AZURE_STORAGE_CONTAINER" {
  value = var.contentContainerName
}

output "AZURE_STORAGE_UPLOAD_CONTAINER" {
  value = var.uploadContainerName
}

output "BACKEND_URI" {
  value = module.webapp.uri
}

output "BACKEND_NAME" {
  value = module.webapp.web_app_name 
}

output "AZURE_OPENAI_RESOURCE_GROUP" {
  value = var.existingAzureOpenAIResourceGroup == "" ? azurerm_resource_group.rg.name : var.existingAzureOpenAIResourceGroup
}

output "AZURE_FORM_RECOGNIZER_ENDPOINT" {
  value = module.aiDocIntelligence.formRecognizerAccountEndpoint
}

output "AZURE_BLOB_DROP_STORAGE_CONTAINER" {
  value = var.uploadContainerName
}

output "AZURE_AI_ENDPOINT" {
  value = module.cognitiveServices.cognitiveServicesEndpoint
}

output "AZURE_AI_LOCATION" {
  value = var.location
}

output "TARGET_TRANSLATION_LANGUAGE" {
  value = var.targetTranslationLanguage
}

output "BLOB_STORAGE_ACCOUNT_ENDPOINT" {
  value = module.storage.primary_blob_endpoint
}

output "AZURE_QUEUE_STORAGE_ENDPOINT" {
  value = module.storage.primary_queue_endpoint
}

output "EMBEDDING_VECTOR_SIZE" {
  value = "1536"
}

output "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME" {
  value = var.azureOpenAIEmbeddingDeploymentName
}

output "EMBEDDING_DEPLOYMENT_NAME" {
  value = var.azureOpenAIEmbeddingDeploymentName
}

output "AZURE_KEYVAULT_NAME" {
  value = module.kvModule.keyVaultName
}

output "CHAT_WARNING_BANNER_TEXT" {
  value = var.chatWarningBannerText
}

output "AZURE_OPENAI_ENDPOINT"  {
  value = module.openaiServices.endpoint
}

output "AZURE_ENVIRONMENT" {
  value = var.azure_environment
}

output "BING_SEARCH_ENDPOINT" {
  value = var.useWebChat ? module.bingSearch[0].endpoint : ""
}

output "BING_SEARCH_KEY" {
  value = var.useWebChat ? module.bingSearch[0].key : ""
}

output "USE_BING_SAFE_SEARCH" {
  value = var.useBingSafeSearch
}

output "AZURE_ARM_MANAGEMENT_API" {
  value = var.azure_arm_management_api
}

output "DNS_PRIVATE_RESOLVER_IP" {
  value = module.network.dns_private_resolver_ip
}

output "AZURE_AI_CREDENTIAL_DOMAIN" {
  value = var.azure_ai_private_link_domain
}

output "AZURE_OPENAI_AUTHORITY_HOST" {
  value = var.azure_openai_authority_host
}

output "AZURE_SEARCH_AUDIENCE" {
  value = var.azure_search_scope
}