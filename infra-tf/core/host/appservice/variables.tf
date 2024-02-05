variable "name" {
  type = string
}

variable "location" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {}
}

// Reference Properties
variable "applicationInsightsName" {
  type = string
  default = ""
}

variable "logAnalyticsWorkspaceName" {
  type = string
  default = ""
}

variable "appServicePlanId" {
  type = string
}

variable "keyVaultName" {
  type = string
}

variable "managedIdentity" {
  type = bool
  default = false
}

variable "runtimeName" {
  type = string
  validation {
    condition     = contains(["dotnet", "dotnetcore", "dotnet-isolated", "node", "python", "java", "powershell", "custom"], var.runtimeName)
    error_message = "The runtimeName must be one of: dotnet, dotnetcore, dotnet-isolated, node, python, java, powershell, custom."
  }
}

variable "runtimeVersion" {
  type = string
}

variable "runtimeNameAndVersion" {
  type = string
  default = ""
}

variable "kind" {
  type = string
  default = "app,linux"
}

variable "allowedOrigins" {
  type = list(string)
  default = []
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

variable "clientAffinityEnabled" {
  type = bool
  default = false
}

variable "enableOryxBuild" {
  type = bool
  default = true
}

variable "functionAppScaleLimit" {
  type = number
  default = -1
}

variable "linuxFxVersion" {
  type = string
  default = ""
}

variable "minimumElasticInstanceCount" {
  type = number
  default = -1
}

variable "numberOfWorkers" {
  type = number
  default = -1
}

variable "scmDoBuildDuringDeployment" {
  type = bool
  default = false
}

variable "use32BitWorkerProcess" {
  type = bool
  default = false
}

variable "ftpsState" {
  type = string
  default = "FtpsOnly"
}

variable "healthCheckPath" {
  type = string
  default = ""
}

variable "aadClientId" {
  type = string
  default = ""
}

variable "tenantId" {
  type = string
  default = ""
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
  default = ""
}

variable "isGovCloudDeployment" {
  type = bool
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "portalURL" {
  type    = string
  default = ""
}

variable "app_settings" {
  description = "A map of app settings"
  type        = map(string)
}

variable "applicationInsightsConnectionString" {
  type    = string
  default = ""
}

variable "keyVaultUri" { 
  type = string
}
