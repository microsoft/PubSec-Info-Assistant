variable "nsg_name" {
  type    = string
}

variable "ddos_name" {
  type    = string
}

variable "ddos_plan_id" {
  type = string
}

variable "vnet_name" {
  type    = string
}

variable "dns_resolver_name" {
  type    = string
}

variable "location" {
  type    = string
}

variable "resourceGroupName" {
  type    = string
}

variable "tags" {
  type    = map(string)
}

variable "vnetIpAddressCIDR" {
  type    = string
}

variable "snetAzureMonitorCIDR" {
  type    = string
}

variable "snetStorageAccountCIDR" {
  type    = string
}

variable "snetCosmosDbCIDR" {
  type    = string
}

variable "snetAzureAiCIDR" {
  type    = string
}

variable "snetKeyVaultCIDR" {
  type    = string
}

variable "snetAppCIDR" {
  type    = string
}

variable "snetEnrichmentCIDR" {
  type    = string
}

variable "snetIntegrationCIDR" {
  type    = string
}

variable "snetSearchServiceCIDR" {
  type    = string
}

variable "snetAzureVideoIndexerCIDR" {
  type    = string
}

variable "snetBingServiceCIDR" {
  type    = string
}

variable "snetAzureOpenAICIDR" {
  type    = string
}

variable "snetFunctionCIDR" {
  type    = string
}

variable "snetACRCIDR" {
  type    = string
}

variable "snetDnsCIDR" {
  type    = string
}

variable "arm_template_schema_mgmt_api" {
  type = string
}

variable "azure_environment" {
  type        = string
}

variable "enabledDDOSProtectionPlan" {
  type = bool
}