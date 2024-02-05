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
  default = ""
}

variable "managedIdentity" {
  type = bool
  default = false
}

// Runtime Properties
variable "runtimeName" {
  type = string
  validation {
    condition     = contains(["dotnet", "dotnetcore", "dotnet-isolated", "node", "python", "java", "powershell", "custom"], var.runtimeName)
    error_message = "The runtimeName must be one of: dotnet, dotnetcore, dotnet-isolated, node, python, java, powershell, custom."
  }
}

variable "runtimeNameAndVersion" {
  type = string
  default = ""
}

variable "runtimeVersion" {
  type = string
}

// Microsoft.Web/sites Properties
variable "kind" {
  type = string
  default = "app,linux"
}

// Microsoft.Web/sites/config
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

variable "logAnalyticsWorkspaceResourceId" {
  type = string
  default = ""
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "applicationInsightsConnectionString" {
  type    = string
  default = ""
}

variable "keyVaultUri" { 
  type = string
}
