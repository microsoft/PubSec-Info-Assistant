variable "name" {
  type = string
}

variable "resourceGroupName" {
  type = string
}

variable "location" {
  type = string
}

variable "serviceResourceId" {
  type = string
}

variable "subnetResourceId" {
  type = string
}

variable "privateDnsZoneResourceIdMonitor" {
  type = string
}

variable "privateDnsZoneResourceIdOpsInsightOms" {
  type = string
}

variable "privateDnsZoneResourceIdOpsInsightOds" {
  type = string
}

variable "privateDnsZoneResourceIdAutomation" {
  type = string
}

variable "privateDnsZoneResourceIdBlob" {
  type = string
}

variable "groupId" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}
