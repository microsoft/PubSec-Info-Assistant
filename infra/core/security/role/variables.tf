variable "principalId" {
  type = string
}

variable "principalType" {
  type = string
  default = "ServicePrincipal"
  validation {
    condition     = contains(["Device", "ForeignGroup", "Group", "ServicePrincipal", "User"], var.principalType)
    error_message = "The principalType must be one of the following: Device, ForeignGroup, Group, ServicePrincipal, User."
  }
}

variable "roleDefinitionId" {
  type = string
}

variable "resourceGroupId" {
  type = string
}

variable "subscriptionId" {
  type = string
}

variable "scope" {
  type = string
}


