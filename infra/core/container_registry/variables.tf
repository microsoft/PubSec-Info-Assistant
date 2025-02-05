variable "name" {
  description = "The name"
  type        = string
}

variable "location" {
  description = "Location for all resources."
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "vnet_name" {
  type = string  
}

variable "subnet_name" {
  type = string
}

variable "is_secure_mode" {
  description = "Specifies whether to deploy in secure mode"
  type        = bool
  default     = true
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "private_dns_zone_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}