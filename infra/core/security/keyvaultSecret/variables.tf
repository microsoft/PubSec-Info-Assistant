variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "key_vault_name" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "secret_value" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "alias" {
  type = string
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}