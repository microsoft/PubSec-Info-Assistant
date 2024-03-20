
variable "vnet_link_name" {
  type = string
}
variable "location" {
  type    = string
}
variable "dnsname" {
    type = string
}

variable "resourceGroupName" {
  type    = string
}
variable "vnet_resource_id" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

