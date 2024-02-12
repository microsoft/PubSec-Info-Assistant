

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