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

variable "resourceGroupName" {
  type    = string
}

variable "keyVaultId" { 
  type = string
}

variable "azure_search_domain" {
  type = string  
}

variable "subnet_id" {
  type = string
  default = ""
}

variable "privateDnsZoneName" {
  type = string
  default = ""
}

variable "subnetResourceId" {
  type = string
}
variable "private_dns_zone_ids" {
  type = set(string)
}

variable "is_secure_mode" {
  type    = bool
  default = false
}

