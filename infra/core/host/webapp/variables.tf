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
  default = "3.12"
}

variable "is_secure_mode" {
  description = "Specifies whether to deploy in secure mode"
  type        = bool
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "private_dns_zone_name" {
  type = string
}

variable "snetIntegration_id" {
  type = string
}

variable "randomString" {
  type = string
}

variable "container_registry" {
  description = "The login server of the container registry"
  type        = string
}

variable "container_registry_admin_username" {
  description = "The admin username of the container registry"
  type        = string
}

variable "container_registry_id" {
  description = "The id of the container registry"
  type        = string
}

variable "container_registry_admin_password" {
  description = "The admin password of the container registry"
  type        = string
}

variable "azure_environment" {
  type        = string
}