variable "environmentName" {
  description = "Name of the the environment which is used to generate a short unique hash used in all resources."
  type        = string
}

variable "location" {
  description = "Primary location for all resources"
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "tenantId" {
  type    = string
  default = ""
}

variable "subscriptionId" {
  type    = string
  default = ""
}

variable "buildNumber" {
  type    = string
  default = "local"
}

variable "cuaEnabled" {
  type    = bool
  default = false
}

variable "cuaId" {
  type    = string
  default = ""
}

variable "ddos_enabled" {
  type    = bool
  default = true
}

variable "ddos_plan_id" {
  type    = string 
}

variable "requireWebsiteSecurityMembership" {
  type    = bool
  default = false
}

variable "enableBingSafeSearch" {
  type    = bool
  default = true
}

variable "enableWebChat" {
  type    = bool
  default = true
}

variable "enableUngroundedChat" {
  type    = bool
  default = false
}

variable "enableMathAssitant" {
  type    = bool
  default = true
}

variable "enableTabularDataAssistant" {
  type    = bool
  default = true
}

variable "enableSharePointConnector" {
  type    = bool
  default = false
}

variable "enableMultimedia" {
  type    = bool
  default = false
  
}
////
// variables that can vary based on the Azure environment being targeted
////
variable "azure_environment" {
  type        = string
  default     = "AzureCloud"
  description = "The Azure Environemnt to target. More info can be found at https://docs.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli?toc=/cli/azure/toc.json&bc=/cli/azure/breadcrumb/toc.json. Defaults to value for 'AzureCloud'"
}

variable "azure_websites_domain" {
  type = string
}

variable "azure_portal_domain" {
  type = string
}

variable "azure_openai_domain" {
  type = string
}

variable "azure_openai_authority_host" {
  type = string
}

variable "azure_arm_management_api" {
  type = string
}

variable "azure_ai_translation_domain" {
  type = string
}

variable "azure_ai_text_analytics_domain" {
  type = string
}

variable "azure_ai_form_recognizer_domain" {
  type = string
}

variable "azure_search_domain" {
  type = string
}

variable "use_semantic_reranker" {
  type    = bool
  default = true
}

variable "azure_storage_domain" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type        = string
  default     = "https://schema.management.azure.com"
  description = "The URI root for ARM template Management API. Defaults to value for 'AzureCloud'"
}

variable "azure_keyvault_domain" {
  type = string
}

variable "cosmosdb_domain" {
  type = string
}

variable "azure_monitor_domain" {
  type = string
}

variable "azure_monitor_oms_domain" {
  type = string
}

variable "azure_monitor_ods_domain" {
  type = string
}

variable "azure_automation_domain" {
  type = string
}

variable "azure_ai_document_intelligence_domain" {
  type = string
}

variable "azure_ai_videoindexer_domain" {
  type = string
}

variable "azure_bing_search_domain" {
  type = string
}

variable "azure_ai_private_link_domain" {
  type = string
}
////

////
// Variables that are used for CI/CD automation
////
variable "isInAutomation" {
  type    = bool
  default = false
}

variable "aadWebClientId" {
  type    = string
  default = ""
}

variable "aadMgmtClientId" {
  type    = string
  default = ""
}

variable "aadMgmtClientSecret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aadMgmtServicePrincipalId" {
  type    = string
  default = ""
}
////

////
// Variables that are used for the Azure OpenAI service
////
variable "useExistingAOAIService" {
  type = bool
}

variable "azureOpenAIServiceName" {
  type = string
}

variable "azureOpenAIResourceGroup" {
  type = string
}

variable "azureOpenAIServiceKey" {
  type      = string
  sensitive = true
}

variable "openAIServiceName" {
  type    = string
  default = ""
}

variable "openAiSkuName" {
  type    = string
  default = "S0"
}

variable "chatGptDeploymentName" {
  type    = string
  default = "gpt-35-turbo-16k"
}

variable "azureOpenAIEmbeddingDeploymentName" {
  type    = string
  default = "text-embedding-ada-002"
}

variable "azureOpenAIEmbeddingsModelName" {
  type    = string
  default = "text-embedding-ada-002"
}

variable "azureOpenAIEmbeddingsModelVersion" {
  type    = string
  default = "2"
}

variable "useAzureOpenAIEmbeddings" {
  type    = bool
  default = true
}

variable "sentenceTransformersModelName" {
  type    = string
  default = "BAAI/bge-small-en-v1.5"
}

variable "sentenceTransformerEmbeddingVectorSize" {
  type    = string
  default = "384"
}

variable "embeddingsDeploymentCapacity" {
  type    = number
  default = 40
}

variable "openai_public_network_access_enabled" {
  type    = string
  default = "Enabled"
}
////

////
// Variables that are used for the secure mode
////
variable "is_secure_mode" {
  type    = bool
  default = false
}

variable "virtual_network_CIDR" {
  type    = string
  default = "10.0.0.0/21"
}

variable "azure_monitor_CIDR" {
  type    = string
  default = "10.0.0.64/26"
}

variable "storage_account_CIDR" {
  type    = string
  default = "10.0.1.0/26"
}

variable "cosmos_db_CIDR" {
  type    = string
  default = "10.0.1.64/26"
}

variable "azure_ai_CIDR" {
  type    = string
  default = "10.0.1.128/26"
}

variable "key_vault_CIDR" {
  type    = string
  default = "10.0.7.64/26"
}

variable "webapp_CIDR" {
  type    = string
  default = "10.0.2.0/26"
}

variable "functions_CIDR" {
  type    = string
  default = "10.0.3.0/26"
}

variable "enrichment_app_CIDR" {
  type    = string
  default = "10.0.4.0/26"
}

variable "search_service_CIDR" {
  type    = string
  default = "10.0.5.0/26"
}

variable "azure_video_indexer_CIDR" {
  type    = string
  default = "10.0.5.128/26"
}

variable "bing_service_CIDR" {
  type    = string
  default = "10.0.6.0/26"
}

variable "azure_openAI_CIDR" {
  type    = string
  default = "10.0.6.128/26"
}

variable "integration_CIDR" {
  type    = string
  default = "10.0.7.0/26"

}
////

variable "formRecognizerSkuName" {
  type    = string
  default = "S0"
}

variable "appServicePlanName" {
  type    = string
  default = ""
}

variable "appServiceSkuSize" {
  description = "The size of the app service plan for the IA website. Must match with the tier value in appServiceSkuTier."
  type = string
  default = "S1"
}

variable "appServiceSkuTier" {
  description = "The tier of the app service plan for the IA website. Must match with the size value in appServiceSkuSize."
  type = string
  default = "Standard"
  
}

variable "enrichmentAppServicePlanName" {
  type    = string
  default = ""
}

variable "enrichmentAppServiceSkuSize" {
  description = "The size of the app service plan for the enrichment service. Must match with the tier value in enrichmentAppServiceSkuTier."
  type = string
  default = "S1"
}

variable "enrichmentAppServiceSkuTier" {
  description = "The tier of the app service plan for the enrichment service. Must match with the size value in enrichmentAppServiceSkuSize."
  type = string
  default = "Standard"
}

variable "logAnalyticsName" {
  type    = string
  default = ""
}

variable "applicationInsightsName" {
  type    = string
  default = ""
}

variable "webappServiceName" {
  type    = string
  default = ""
}

variable "enrichmentServiceName" {
  type    = string
  default = ""
}

variable "functionsAppName" {
  type    = string
  default = ""
}

variable "functionsAppSkuSize" {
  description = "The size of the app service plan for the functions app. Must match with the tier value in functionsAppSkuTier."
  type = string
  default = "S2"
}

variable "functionsAppSkuTier" {
  description = "The tier of the app service plan for the functions app. Must match with the size value in functionsAppSkuSize."
  type = string
  default = "Standard"
}

variable "videoIndexerName" {
  type    = string
  default = ""
}

variable "searchServicesName" {
  type    = string
  default = ""
}

variable "searchServicesSkuName" {
  type    = string
  default = "standard"
}

variable "storageAccountName" {
  type    = string
  default = ""
}

variable "contentContainerName" {
  type    = string
  default = "content"
}

variable "uploadContainerName" {
  type    = string
  default = "upload"
}

variable "functionLogsContainerName" {
  type    = string
  default = "logs"
}

variable "searchIndexName" {
  type    = string
  default = "vector-index"
}

variable "chatWarningBannerText" {
  type    = string
  default = ""
}

variable "chatGptModelName" {
  type    = string
  default = "gpt-35-turbo-16k"
}

variable "chatGptModelVersion" {
  type    = string
  default = "0613"
}

variable "chatGptDeploymentCapacity" {
  type    = number
  default = 240
}

variable "chunkTargetSize" {
  type    = string
  default = "750"
}

variable "targetPages" {
  type    = string
  default = "ALL"
}

variable "formRecognizerApiVersion" {
  type    = string
  default = "2023-07-31"
}

variable "queryTermLanguage" {
  type    = string
  default = "English"
}

variable "maxSecondsHideOnUpload" {
  type    = string
  default = "300"
}

variable "maxSubmitRequeueCount" {
  type    = string
  default = "10"
}

variable "pollQueueSubmitBackoff" {
  type    = string
  default = "60"
}

variable "pdfSubmitQueueBackoff" {
  type    = string
  default = "60"
}

variable "maxPollingRequeueCount" {
  type    = string
  default = "10"
}

variable "submitRequeueHideSeconds" {
  type    = string
  default = "1200"
}

variable "pollingBackoff" {
  type    = string
  default = "30"
}

variable "maxReadAttempts" {
  type    = string
  default = "5"
}

variable "maxEnrichmentRequeueCount" {
  type    = string
  default = "10"
}

variable "enrichmentBackoff" {
  type    = string
  default = "60"
}

variable "targetTranslationLanguage" {
  type    = string
  default = "en"
}

variable "pdfSubmitQueue" {
  type    = string
  default = "pdf-submit-queue"
}

variable "pdfPollingQueue" {
  type    = string
  default = "pdf-polling-queue"
}

variable "nonPdfSubmitQueue" {
  type    = string
  default = "non-pdf-submit-queue"
}

variable "mediaSubmitQueue" {
  type    = string
  default = "media-submit-queue"
}

variable "textEnrichmentQueue" {
  type    = string
  default = "text-enrichment-queue"
}

variable "imageEnrichmentQueue" {
  type    = string
  default = "image-enrichment-queue"
}

variable "embeddingsQueue" {
  type    = string
  default = "embeddings-queue"
}

variable "applicationtitle" {
  type    = string
  default = ""
}

variable "video_indexer_api_version" {
  type    = string
  default = "2024-01-01"
}

variable "enableDevCode" {
  type    = bool
  default = false
}

//Provide DDOS ID if you want to enable DDOS protection

variable "maxCsvFileSize" {
  type    = string
  default = "20"
}