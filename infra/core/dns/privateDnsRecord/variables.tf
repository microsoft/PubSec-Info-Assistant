variable "privateEndpointName" {
  type = string
}

variable "privateDnsZoneName" {
  type = string
}

variable "groupId" {
  type = string
}

variable "ipAddress" {
  type = string
}

variable "hostname" {
  type = string
}

variable "reusePrivateDnsZone" {
  type    = bool
  default = false
}