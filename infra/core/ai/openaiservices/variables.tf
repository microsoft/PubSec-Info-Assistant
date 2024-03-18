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

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "outbound_network_access_restricted" {
  type    = bool
  default = false
}

variable "network_acls_default_action" {
  type        = string
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_rules. Possible values are Allow and Deny."
  default     = "Deny"
}

variable "network_acls_ip_rules" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the Cognitive Account."
  default     = []
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

variable "keyVaultId" { 
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

variable "subnet_id" {
  type = string
  default = ""
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "subnetResourceId" {
  type = string
}
