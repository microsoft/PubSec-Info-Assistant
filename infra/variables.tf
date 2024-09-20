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

variable "requireWebsiteSecurityMembership" {
  type    = bool
  default = false
}

//// Feature flags and supporting variables
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
////

//// Variables that can vary based on the Azure environment being targeted
variable "azure_environment" {
  type        = string
  default     = "AzureCloud"
  description = "The Azure Environemnt to target. More info can be found at https://docs.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli?toc=/cli/azure/toc.json&bc=/cli/azure/breadcrumb/toc.json. Defaults to value for 'AzureCloud'"
}

variable "azure_websites_domain" {
  type        = string
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

variable "azure_search_domain" {
  type = string
}

variable "azure_search_scope" {
  type = string
}

variable "azure_acr_domain" {
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

variable "azure_bing_search_domain" {
  type = string
}

variable "azure_ai_private_link_domain" {
  type = string
}
////

//// Variables that are used for CI/CD automation
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
  type = string
  default = ""
}
////

//// Variables that are used for the Azure OpenAI service
variable "useExistingAOAIService" {
  type = bool
}

variable "azureOpenAIServiceName" {
  type = string
}

variable "azureOpenAIResourceGroup" {
  type = string
}

variable "openAIServiceName" {
  type = string
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

variable "chatGptModelName" {
  type    = string
  default = "gpt-35-turbo-16k"
}

variable "chatGptModelSkuName" {
  type    = string
  default = "Standard"
  
}

variable "chatGptModelVersion" {
  type    = string
  default = "0613"
}

variable "chatGptDeploymentCapacity" {
  type    = number
  default = 240
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

variable "azureOpenAIEmbeddingsModelSku" {
  type    = string
  default = "Standard"
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
  default = 240
}
////

//// Variables that are used for Secure Mode
variable "is_secure_mode" {
  type    = bool
  default = false
}

variable "virtual_network_CIDR" {
  type    = string
  default = "10.0.8.0/24"
}

variable "azure_monitor_CIDR" {
  type    = string
  default = "10.0.8.0/27"
}

variable "storage_account_CIDR" {
  type    = string
  default = "10.0.8.32/28"
}

variable "cosmos_db_CIDR" {
  type    = string
  default = "10.0.8.48/29"
}

variable "azure_ai_CIDR" {
  type    = string
  default = "10.0.8.56/29"
}

variable "webapp_CIDR" {
  type    = string
  default = "10.0.8.64/29"
}

variable "key_vault_CIDR" {
  type    = string
  default = "10.0.8.72/29"
}

variable "functions_CIDR" {
  type    = string
  default = "10.0.8.80/29"
}

variable "enrichment_app_CIDR" {
  type    = string
  default = "10.0.8.88/29"
}

variable "search_service_CIDR" {
  type    = string
  default = "10.0.8.96/29"
}

variable "azure_video_indexer_CIDR" {
  type    = string
  default = "10.0.8.104/29"
}

variable "bing_service_CIDR" {
  type    = string
  default = "10.0.8.112/29"
}

variable "azure_openAI_CIDR" {
  type    = string
  default = "10.0.8.120/29"
}

variable "integration_CIDR" {
  type    = string
  default = "10.0.8.192/26"
}

variable "acr_CIDR" {
  type    = string
  default = "10.0.8.128/29"
}

variable "dns_CIDR" {
  type    = string
  default = "10.0.8.176/28"
}

variable "ddos_plan_id" {
  type    = string
  default = ""
}

variable "openai_public_network_access_enabled" {
  type    = string
  default = "Enabled"
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}

variable "enabledDDOSProtectionPlan" {
  type        = bool
  description = "This variable is used to enable or disable DDOS protection plan"
  default = false
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
  default = "P2v3"
}

variable "enrichmentAppServiceSkuTier" {
  description = "The tier of the app service plan for the enrichment service. Must match with the size value in enrichmentAppServiceSkuSize."
  type = string
  default = "PremiumV3"
}

variable "logAnalyticsName" {
  type    = string
  default = ""
}

variable "applicationInsightsName" {
  type    = string
  default = ""
}

variable "backendServiceName" {
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
  type = string
  default = "2024-01-01"
}

variable "enableDevCode" {
  type    = bool
  default = false
}

variable "maxCsvFileSize" {
  type    = string
  default = "20"
}

variable "entraOwners" {
  type    = string
  default = ""
  description = "Comma-separated list of owner emails"
}

variable "serviceManagementReference" {
  type    = string
  default = ""
}

variable "password_lifetime" {
  type    = number
  default = 365
  description = "The number of days used as the lifetime for passwords"  
}