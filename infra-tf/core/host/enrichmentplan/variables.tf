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

variable "kind" {
  type = string
  default = ""
}

variable "reserved" {
  type = bool
  default = true
}

variable "sku" {
  type = map(string)
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "storageAccountId" {
  type    = string
  default = ""
}