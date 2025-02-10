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

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_id" {
  type = string
  
}

variable "outbound_network_access_restricted" {
  type    = bool
  default = false
}

variable "network_acls_ip_rules" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the Cognitive Account."
  default     = []
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
}

variable "existingAzureOpenAIServiceName" {
  type = string
}

variable "existingAzureOpenAIResourceGroup" {
  type = string
}

variable "existingAzureOpenAILocation" {
  type = string
}