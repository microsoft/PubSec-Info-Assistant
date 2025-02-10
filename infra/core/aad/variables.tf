variable "randomString" {
  type = string
}

variable "requireWebsiteSecurityMembership" {
  type = bool
  default = false
}

variable "azure_websites_domain" {
  type        = string
}

variable "useCustomEntra" {
  type    = bool
  default = false
}

variable "aadWebClientId" {
  type = string
}

variable "aadMgmtClientId" {
  type = string
}

variable "aadMgmtServicePrincipalId" {
  type = string
}

variable "entraOwners" {
  type    = string
  default = ""
  description = "Comma-separated list of owner emails"
}

variable "serviceManagementReference" {
  type      = string
  sensitive = true
}

variable "password_lifetime" {
  type      = number
}