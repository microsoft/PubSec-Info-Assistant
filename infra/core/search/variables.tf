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
  type = string
}

variable "replica_count" {
  type = number
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

variable "azure_search_domain" {
  type = string  
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
  default = ""
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "storage_account_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "deployment_public_ip" {
  description = "The public IP address of the deployment machine"
  type        = string
}

variable "cognitive_services_account_id" {
  type = string
}

variable "cognitive_services_account_name" {
  type = string
}