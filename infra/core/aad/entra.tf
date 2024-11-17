/* Copyright (c) DataReason.
 Code for On-Premises Deployment. */

provider "keycloak" {
  client_id     = var.keycloak_client_id
  client_secret = var.keycloak_client_secret
  realm         = var.keycloak_realm
  url           = var.keycloak_url
}

resource "keycloak_realm" "realm" {
  realm   = var.keycloak_realm
  enabled = true
}

resource "keycloak_openid_client" "web_app" {
  realm_id            = keycloak_realm.realm.id
  client_id           = "infoasst_web_access_${var.randomString}"
  name                = "infoasst_web_access_${var.randomString}"
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
  redirect_uris       = ["https://infoasst-web-${var.randomString}.${var.domain}/.auth/login/keycloak/callback"]
  valid_redirect_uris = ["https://infoasst-web-${var.randomString}.${var.domain}/.auth/login/keycloak/callback"]
  web_origins         = ["*"]
  client_secret       = var.keycloak_client_secret
}

resource "keycloak_openid_client" "mgmt_app" {
  realm_id            = keycloak_realm.realm.id
  client_id           = "infoasst_mgmt_access_${var.randomString}"
  name                = "infoasst_mgmt_access_${var.randomString}"
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
  client_secret       = var.keycloak_client_secret