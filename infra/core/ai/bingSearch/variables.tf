variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "key_vault_name" { 
  type = string
  sensitive   = true
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}