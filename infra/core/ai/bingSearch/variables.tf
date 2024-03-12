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