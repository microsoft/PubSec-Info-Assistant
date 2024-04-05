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

variable "snetAppInboundCIDR" {
  type    = string
}

variable "snetAppOutboundCIDR" {
  type    = string
}

variable "snetFunctionInboundCIDR" {
  type    = string
}

variable "snetFunctionOutboundCIDR" {
  type    = string
}

variable "snetEnrichmentInboundCIDR" {
  type    = string
}

variable "snetEnrichmentOutboundCIDR" {
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