variable "nsg_name" {
  type    = string
}

variable "ddos_name" {
  type    = string
}

variable "ddos_enabled"  {
  type    = bool
}

variable "vnet_name" {
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

variable "SnetFunctionCIDR" {
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

