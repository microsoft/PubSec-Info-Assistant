variable "name" {
  description = "The name"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "" // Replace with a function or data source to fetch the location of the resource group
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "kvAccessObjectId" {
  description = "The access object ID for the key vault"
  type        = string
}

variable "spClientSecret" {
  description = "The client secret for the service principal"
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "is_secure_mode" {
  description = "Specifies whether to deploy in secure mode"
  type        = bool
  default     = false
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string  
}

variable "subnet_id" {
  type = string
}

variable "azure_keyvault_domain" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}