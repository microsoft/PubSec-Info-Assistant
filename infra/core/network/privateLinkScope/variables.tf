variable "subnetResourceId" {
  type = string
}

variable "workspaceId" {
  type = string
}

variable "appInsightsId" {
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

variable "location" {
  type    = string
}

variable "resourceGroupName" {
  type    = string
}

variable "tags" {
  type    = map(string)
}

variable "name" {
  type    = string
}