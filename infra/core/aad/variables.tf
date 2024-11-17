# Copyright (c) DataReason.
### Code for On-Premises Deployment.

variable "keycloak_client_id" {
  type = string
}

variable "keycloak_client_secret" {
  type = string
  sensitive = true
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_url" {
  type = string
}

variable "randomString" {
  type = string
}

variable "domain" {
  type = string
}