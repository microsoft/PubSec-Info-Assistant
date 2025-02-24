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
variable "tables" {
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

variable "logAnalyticsWorkspaceResourceId" {
  type = string
}

variable "useNetworkSecurityPerimeter" {
  type = bool
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

variable "deployment_machine_ip" {
  description = "The public IP address of the deployment machine"
  type = set(string)
}