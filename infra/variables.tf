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

variable "useCUA" {
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

variable "azure_sts_issuer_domain" {
  type    = string
  default = "sts.windows.net"
}

//// Feature flags and supporting variables
variable "useBingSafeSearch" {
  type    = bool
  default = true
}

variable "useWebChat" {
  type    = bool
  default = true
}

variable "useUngroundedChat" {
  type    = bool
  default = false
}

variable "useNetworkSecurityPerimeter" {
  type    = bool
  default = false
}
////

//// Variables that can vary based on the Azure environment being targeted
variable "azure_environment" {
  type        = string
  default     = "AzureCloud"
  description = "The Azure Environment to target. More info can be found at https://docs.microsoft.com/cli/azure/manage-clouds-azure-cli?toc=/cli/azure/toc.json&bc=/cli/azure/breadcrumb/toc.json. Defaults to value for 'AzureCloud'"
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

variable "azure_keyvault_domain" {
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

variable "useCustomEntra" {
  type    = bool
  default = false
  description = "This variable is used to enable or disable custom entra"
}

variable "aadWebClientId" {
  type    = string
  default = ""
}

variable "aadMgmtClientId" {
  type    = string
  default = ""
}

variable "aadMgmtServicePrincipalId" {
  type = string
  default = ""
}

//// Variables that are used for the Azure OpenAI service
variable "existingAzureOpenAIServiceName" {
  type = string
}

variable "existingAzureOpenAIResourceGroup" {
  type = string
}

variable "existingAzureOpenAILocation" {
  type = string
}

variable "openAiSkuName" {
  type    = string
  default = "S0"
}

variable "chatGptDeploymentName" {
  type    = string
  default = "gpt-4o"
}

variable "chatGptModelName" {
  type    = string
  default = "gpt-4o"
}

variable "chatGptModelSkuName" {
  type    = string
  default = "Standard"
}

variable "chatGptModelVersion" {
  type    = string
  default = "2024-05-13"
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

variable "embeddingsDeploymentCapacity" {
  type    = number
  default = 240
}
////

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

variable "azure_ai_CIDR" {
  type    = string
  default = "10.0.8.56/29"
}

variable "key_vault_CIDR" {
  type    = string
  default = "10.0.8.72/29"
}

variable "webapp_CIDR" {
  type    = string
  default = "10.0.8.64/29"
}

variable "search_service_CIDR" {
  type    = string
  default = "10.0.8.96/29"
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

variable "dns_CIDR" {
  type    = string
  default = "10.0.8.176/28"
}

variable "ddos_plan_id" {
  type    = string
  default = ""
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}

variable "useDDOSProtectionPlan" {
  type        = bool
  description = "This variable is used to enable or disable DDOS protection plan"
  default = false
}

variable "formRecognizerSkuName" {
  type    = string
  default = "S0"
}

variable "appServicePlanName" {
  type    = string
  default = ""
}

variable "appServiceSkuSize" {
  description = "The size of the app service plan for the IA website."
  type = string
  default = "P0v3"
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

variable "searchServicesName" {
  type    = string
  default = ""
}

variable "searchServicesSkuName" {
  type    = string
  default = "standard3"
}

variable "searchServicesReplicaCount" {
  type    = number
  default = 3
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

variable "targetTranslationLanguage" {
  type    = string
  default = "en"
}

variable "applicationtitle" {
  type    = string
  default = ""
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

variable "deployment_public_ip" {
  description = "The public IP address of the deployment machine"
  type        = set(string)
}



