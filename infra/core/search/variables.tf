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

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "standard"
  }
}

variable "authOptions" {
  type = map(string)
  default = {}
}

variable "semanticSearch" {
  type = string
  default = "disabled"
}

variable "isGovCloudDeployment" {
  type = bool
}

variable "resourceGroupName" {
  type    = string
}

variable "keyVaultId" { 
  type = string
}