# Copyright (c) DataReason.
### Code for On-Premises Deployment.

variable "postgresql_host" {
  type = string
}

variable "postgresql_port" {
  type = number
}

variable "postgresql_username" {
  type = string
}

variable "postgresql_password" {
  type = string
  sensitive = true
}

variable "postgresql_database" {
  type = string
}

variable "log_database_name" {
  type = string
}

variable "log_schema_name" {
  type = string
}

variable "log_table_name" {
  type = string
}