variable "name" {
  type = string
}

variable "location" {
  type    = string
  default = "" 
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "deployments" {
  type    = list(any)
  default = []
}

variable "kind" {
  type    = string
  default = "OpenAI"
}

variable "publicNetworkAccess" {
  type    = string
  default = "Enabled"
}

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "S0"
  }
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "isGovCloudDeployment" {
  type    = bool
  default = false
}

variable "keyVaultId" { 
  type = string
}

variable "useExistingAOAIService" {
  type    = bool
  default = false
}

variable "openaiServiceKey" {
  description = "The OpenAI service key"
  type        = string
}
