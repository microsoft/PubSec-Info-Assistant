

variable "principalType" {
  type = string
  default = "ServicePrincipal"
  validation {
    condition     = contains(["Device", "ForeignGroup", "Group", "ServicePrincipal", "User"], var.principalType)
    error_message = "The principalType must be one of the following: Device, ForeignGroup, Group, ServicePrincipal, User."
  }
}


variable "resourceGroupId" {
  type = string
}

variable "subscriptionId" {
  type = string
}


variable "name" {
  description = "The name"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "" // Replace with a function or data source to fetch the location of the resource group
}

variable "kvAccessObjectId" {
  description = "The access object ID for the key vault"
  type        = string
}

variable "searchServiceKey" {
  description = "The search service key"
  type        = string
}

variable "openaiServiceKey" {
  description = "The OpenAI service key"
  type        = string
}

variable "cosmosdbKey" {
  description = "The CosmosDB key"
  type        = string
}

variable "formRecognizerKey" {
  description = "The Form Recognizer key"
  type        = string
}

variable "blobConnectionString" {
  description = "The blob connection string"
  type        = string
}

variable "enrichmentKey" {
  description = "The enrichment key"
  type        = string
}

variable "spClientSecret" {
  description = "The client secret for the service principal"
  type        = string
}

variable "blobStorageKey" {
  description = "The blob storage key"
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}