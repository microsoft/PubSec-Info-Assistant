variable "nsp_name" {
  type    = string
}

variable "nsp_profile_name" {
  type    = string
}

variable "location" {
  type    = string
}

variable "resourceGroupName" {
  type    = string
}

variable "tags" {
  type    = map(string)
}

variable "arm_template_schema_mgmt_api" {
  type = string
}