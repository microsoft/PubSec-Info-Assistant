variable "name" {
  type = string
}

variable "location" {
  type = string
  default = "Your_Resource_Group_Location"
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "accessTier" {
  type = string
  default = "Hot"
}

variable "allowBlobPublicAccess" {
  type = bool
  default = false
}

variable "allowCrossTenantReplication" {
  type = bool
  default = true
}

variable "allowSharedKeyAccess" {
  type = bool
  default = true
}

variable "defaultToOAuthAuthentication" {
  type = bool
  default = false
}

variable "deleteRetentionPolicy" {
  type = map(string)
  default = {}
}

variable "dnsEndpointType" {
  type = string
  default = "Standard"
}

variable "kind" {
  type = string
  default = "StorageV2"
}

variable "minimumTlsVersion" {
  type = string
  default = "TLS1_2"
}

variable "publicNetworkAccess" {
  type = string
  default = "Disabled"
}

variable "sku" {
  type = object({
    name = string
  })
  default = {
    name = "Standard"
  }
}

variable "containers" {
  type = list(string)
  default = []
}

variable "queueNames" {
  type = list(string)
  default = []
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "key_vault_name" { 
  type = string
}

variable "is_secure_mode" {
  type    = bool
  default = false
}

variable "subnet_name" {
  type    = string
}

variable "vnet_name" {
  type    = string
}

variable "privateDnsZoneName" {
  type    = string
  default = ""
}

variable "private_dns_zone_ids" {
  type = set(string)
}

variable "arm_template_schema_mgmt_api" {
  type        = string
}

variable "network_rules_allowed_subnets" {
  type = set(string)
}

variable "kv_secret_expiration" {
  type = string
  description = "The value for key vault secret expiration in  seconds since 1970-01-01T00:00:00Z"
}

variable "logAnalyticsWorkspaceResourceId" {
  type = string
}