variable "name" {
  type = string
}

variable "location" {
  type    = string
  default = "" 
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "deployments" {
  type    = list(any)
  default = []
}

variable "kind" {
  type    = string
  default = "OpenAI"
}

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "S0"
  }
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "key_vault_name" { 
  type = string
}

variable "useExistingAOAIService" {
  type    = bool
  default = false
}

variable "openaiServiceKey" {
  description = "The OpenAI service key"
  type        = string
}

variable "is_secure_mode" {
  type = bool
  default = false
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

variable "outbound_network_access_restricted" {
  type    = bool
  default = false
}

variable "network_acls_ip_rules" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the Cognitive Account."
  default     = []
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
}