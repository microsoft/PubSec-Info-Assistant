variable "name" {
  description = "The name"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "" // Replace with a function or data source to fetch the location of the resource group
}

variable "tags" {
  description = "Tags for the resources"
  type    = map(string)
  default = {}
}

variable "kvAccessObjectId" {
  description = "The access object ID for the key vault"
  type        = string
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

variable "azure_keyvault_domain" {
  type = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "deployment_machine_ip" {
  description = "The public IP address of the deployment machine"
  type = string
}

variable "expiration_date" {
  description = "The expiration time for the Key Vault secret"
  type        = string
}

variable "bing_secret_value" {
  type = string
}

variable "useNetworkSecurityPerimeter" {
  type    = bool
}

variable "nsp_name" {
  type = string
}

variable "nsp_assoc_name" {
  type = string
}

variable "nsp_profile_id" {
  type = string
}