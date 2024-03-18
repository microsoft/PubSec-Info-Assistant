variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "serviceResourceId" {
  type = string
}

variable "subnetResourceId" {
  type = string
}

variable "groupId" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {}
}
variable "private_dns_zone_ids" {
  type = set(string)
}