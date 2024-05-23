variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "standard"
  }
}

variable "authOptions" {
  type = map(string)
  default = {}
}

variable "semanticSearch" {
  type = string
  default = "disabled"
}

variable "resourceGroupName" {
  type    = string
}

variable "azure_search_domain" {
  type = string  
}

variable "key_vault_name" { 
  type = string
}

variable "is_secure_mode" {
  type = bool
  default = false
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
  default = ""
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}