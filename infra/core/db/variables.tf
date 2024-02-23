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

variable "defaultConsistencyLevel" {
  description = "The default consistency level of the Cosmos DB account."
  type        = string
  default     = "Session"
  validation {
    condition     = contains(["Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong"], var.defaultConsistencyLevel)
    error_message = "The defaultConsistencyLevel must be one of the following: Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong."
  }
}

variable "maxStalenessPrefix" {
  description = "Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647."
  type        = number
  default     = 100000
}

variable "maxIntervalInSeconds" {
  description = "Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400."
  type        = number
  default     = 300
}

variable "systemManagedFailover" {
  description = "Enable system managed failover for regions"
  type        = bool
  default     = true
}

variable "logDatabaseName" {
  description = "The name for the log database"
  type        = string
}

variable "logContainerName" {
  description = "The name for the log container"
  type        = string
}

variable "tagDatabaseName" {
  description = "The name for the tag database"
  type        = string
}

variable "tagContainerName" {
  description = "The name for the tag container"
  type        = string
}

variable "autoscaleMaxThroughput" {
  description = "Maximum autoscale throughput for the container"
  type        = number
  default     = 1000
}

variable "resourceGroupName" {
  type    = string
  default = ""
}

variable "keyVaultId" { 
  type = string
}