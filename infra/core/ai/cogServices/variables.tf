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

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "subnetResourceId" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "subnet_name" {
  type    = string
}

variable "vnet_name" {
  type    = string
}