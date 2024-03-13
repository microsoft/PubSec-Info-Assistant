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

variable "isInAutomation" {
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

variable "aadMgmtClientSecret" {
  type      = string
  sensitive = true
}