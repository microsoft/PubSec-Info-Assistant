variable "plan_name" {
  type = string
}

variable "name" {
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

variable "alwaysOn" {
  type = bool
  default = true
}

variable "appCommandLine" {
  type = string
  default = ""
}

variable "appSettings" {
  type = map(string)
  default = {}
}

variable "ftpsState" {
  type = string
  default = "FtpsOnly"
}

variable "healthCheckPath" {
  type = string
  default = ""
}

variable "applicationInsightsConnectionString" {
  type    = string
  default = ""
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
  default = ""
}

variable "keyVaultUri" { 
  type = string
}

variable "keyVaultName" {
  type = string
  default = ""
}

variable "managedIdentity" {
  type = bool
  default = false
}

variable "scmDoBuildDuringDeployment" {
  type = bool
  default = true
}

variable "enableOryxBuild" {
  type = bool
  default = true
}

variable "image_name" {
  description = "The Name of the image file in the Container Registry"
  type        = string
}

variable "container_registry" {
  description = "The login server of the container registry"
  type        = string
}

variable "container_registry_admin_username" {
  description = "The admin username of the container registry"
  type        = string
}

variable "container_registry_admin_password" {
  description = "The admin password of the container registry"
  type        = string
}