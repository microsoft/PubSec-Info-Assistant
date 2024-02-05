variable "name" {
  description = "Name of the function app"
  type        = string
}

variable "appServicePlanId" {
  description = "Id of the function app hosting plan"
  type        = string
}

variable "location" {
  description = "Location of the function app"
  type        = string
  default     = "resourceGroup().location"
}

variable "tags" {
  description = "Tags for the function app"
  type        = map(string)
  default     = {}
}

variable "runtime" {
  description = "Runtime of the function app"
  type        = string
  default     = "python"
}

variable "appInsightsInstrumentationKey" {
  description = "Application Insights Instrumentation Key"
  type        = string
}

variable "appInsightsConnectionString" {
  description = "Application Insights Connection String"
  type        = string
}

variable "blobStorageAccountName" {
  description = "Azure Blob Storage Account Name"
  type        = string
}

variable "blobStorageAccountEndpoint" {
  description = "Azure Blob Storage Account Endpoint"
  type        = string
}

variable "blobStorageAccountUploadContainerName" {
  description = "Azure Blob Storage Account Upload Container Name"
  type        = string
}

variable "blobStorageAccountOutputContainerName" {
  description = "Azure Blob Storage Account Output Container Name"
  type        = string
}

variable "blobStorageAccountLogContainerName" {
  description = "Azure Blob Storage Account Log Container Name"
  type        = string
}

variable "chunkTargetSize" {
  description = "Chunk Target Size"
  type        = string
}

variable "targetPages" {
  description = "Target Pages"
  type        = string
}

variable "formRecognizerApiVersion" {
  description = "Form Recognizer API Version"
  type        = string
}

variable "formRecognizerEndpoint" {
  description = "Form Recognizer Endpoint"
  type        = string
}

variable "CosmosDBEndpointURL" {
  description = "CosmosDB Endpoint"
  type        = string
}

variable "CosmosDBLogDatabaseName" {
  description = "CosmosDB Log Database Name"
  type        = string
}

variable "CosmosDBLogContainerName" {
  description = "CosmosDB Log Container Name"
  type        = string
}

variable "CosmosDBTagsDatabaseName" {
  description = "CosmosDB Tags Database Name"
  type        = string
}

variable "CosmosDBTagsContainerName" {
  description = "CosmosDB Tags Container Name"
  type        = string
}

variable "pdfSubmitQueue" {
  description = "Name of the submit queue for PDF files"
  type        = string
}

variable "pdfPollingQueue" {
  description = "Name of the queue used to poll for completed FR processing"
  type        = string
}

variable "nonPdfSubmitQueue" {
  description = "The queue which is used to trigger processing of non-PDF files"
  type        = string
}

variable "mediaSubmitQueue" {
  description = "The queue which is used to trigger processing of media files"
  type        = string
}

variable "textEnrichmentQueue" {
  description = "The queue which is used to trigger processing of text files"
  type        = string
}

variable "imageEnrichmentQueue" {
  description = "The queue which is used to trigger processing of image files"
  type        = string
}

variable "maxSecondsHideOnUpload" {
  description = "The maximum number of seconds  between uploading a file and submitting it to FR"
  type        = string
}

variable "maxSubmitRequeueCount" {
  description = "The maximum number of times a file can be resubmitted to FR due to throttling or internal FR capacity limitations"
  type        = string
}

variable "pollQueueSubmitBackoff" {
  description = "the number of seconds that a message sleeps before we try to poll for FR completion"
  type        = string
}

variable "pdfSubmitQueueBackoff" {
  description = "The number of seconds a message sleeps before trying to resubmit due to throttling request from FR"
  type        = string
}

variable "maxPollingRequeueCount" {
  description = "Max times we will retry the submission due to throttling or internal errors in FR"
  type        = string
}

variable "submitRequeueHideSeconds" {
  description = "Number of seconds to delay before trying to resubmit a doc to FR when it reported an internal error"
  type        = string
}

variable "pollingBackoff" {
  description = "The number of seconds we will hide a message before trying to repoll due to FR still processing a file. This is the default value that escalates exponentially"
  type        = string
}

variable "maxReadAttempts" {
  description = "The maximum number of times we will retry to read a full processed document from FR. Failures in read may be due to network issues downloading the large response"
  type        = string
}

variable "enrichmentEndpoint" {
  description = "Endpoint of the enrichment service"
  type        = string
}

variable "enrichmentName" {
  description = "Name of the enrichment service"
  type        = string
}

variable "enrichmentLocation" {
  description = "Location of the enrichment service"
  type        = string
}

variable "targetTranslationLanguage" {
  description = "Target language to translate content to"
  type        = string
}

variable "maxEnrichmentRequeueCount" {
  description = "Max times we will retry the enriichment due to throttling or internal errors"
  type        = string
}

variable "enrichmentBackoff" {
  description = "The number of seconds we will hide a message before trying to call enrichment service throttling. This is the default value that escalates exponentially"
  type        = string
}

variable "enableDevCode" {
  description = "A boolean value that flags if a user wishes to enable or disable code under development"
  type        = bool
}

variable "EMBEDDINGS_QUEUE" {
  description = "A boolean value that flags if a user wishes to enable or disable code under development"
  type        = string
}

variable "azureSearchIndex" {
  description = "Name of the Azure Search Service index to post data to for ingestion"
  type        = string
}

variable "azureSearchServiceEndpoint" {
  description = "Endpoint of the Azure Search Service to post data to for ingestion"
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "endpointSuffix" {
  type    = string
  default = "core.windows.net"
}

variable "keyVaultUri" { 
  type = string
}

variable "keyVaultName" {
  type = string
}