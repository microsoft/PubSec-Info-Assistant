variable "name" {
  type = string
}

variable "plan_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "kind" {
  type = string
  default = ""
}

variable "reserved" {
  type = bool
  default = true
}

variable "sku" {
  type = map(string)
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "storageAccountId" {
  type    = string
  default = ""
}

variable "managedIdentity" {
  type = bool
  default = false
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
  default = ""
}

variable "applicationInsightsConnectionString" {
  type    = string
  default = ""
}

variable "keyVaultUri" { 
  type = string
}

variable "keyVaultName" {
  type = string
}

variable "aadClientId" {
  type = string
  default = ""
}

variable "tenantId" {
  type = string
  default = ""
}

variable "scmDoBuildDuringDeployment" {
  type = bool
  default = true
}

variable "enableOryxBuild" {
  type = bool
  default = true
}

variable "appSettings" {
  type = map(string)
  default = {}
}

variable "ftpsState" {
  type = string
  default = "FtpsOnly"
}

variable "alwaysOn" {
  type = bool
  default = true
}

variable "appCommandLine" {
  type = string
  default = ""
}

variable "healthCheckPath" {
  type = string
  default = ""
}

variable "azure_portal_domain" {
  type    = string
  default = ""
}

variable "allowedOrigins" {
  type = list(string)
  default = []
}

variable "runtimeVersion" {
  type    = string
  default = "3.10"
}