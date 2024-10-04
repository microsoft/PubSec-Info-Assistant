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