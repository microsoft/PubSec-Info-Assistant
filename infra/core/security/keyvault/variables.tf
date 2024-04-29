

variable "principalType" {
  type = string
  default = "ServicePrincipal"
  validation {
    condition     = contains(["Device", "ForeignGroup", "Group", "ServicePrincipal", "User"], var.principalType)
    error_message = "The principalType must be one of the following: Device, ForeignGroup, Group, ServicePrincipal, User."
  }
}

variable "resourceGroupId" {
  type = string
}

variable "subscriptionId" {
  type = string
}


variable "name" {
  description = "The name"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "" // Replace with a function or data source to fetch the location of the resource group
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "kvAccessObjectId" {
  description = "The access object ID for the key vault"
  type        = string
}

variable "spClientSecret" {
  description = "The client secret for the service principal"
  type        = string
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "is_secure_mode" {
  description = "Specifies whether to deploy in secure mode"
  type        = bool
  default     = false
}

variable "snetIntegration_id" {
  type = string
}

variable "vnet_id" {
  description = "VNet ID needed for some configurations"
  type = string
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "kv_subnet" {
  type = string  
}

variable "userIpAddress" {
  type = string
}