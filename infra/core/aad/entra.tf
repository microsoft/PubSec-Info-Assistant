data "azurerm_client_config" "current" {}

resource "azuread_application" "aad_web_app" {
  count                         = var.isInAutomation ? 0 : 1
  display_name                  = "infoasst_web_access_${var.randomString}"
  identifier_uris               = ["api://infoasst-${var.randomString}"]
  owners                        = [data.azurerm_client_config.current.object_id]
  sign_in_audience              = "AzureADMyOrg"
  oauth2_post_response_required = true
  service_management_reference = var.serviceManagementReference
  web {
    redirect_uris = ["https://infoasst-web-${var.randomString}.${var.azure_websites_domain}/.auth/login/aad/callback"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "aad_web_sp" {
  count                         = var.isInAutomation ? 0 : 1
  client_id                     = azuread_application.aad_web_app[0].client_id
  app_role_assignment_required  = var.requireWebsiteSecurityMembership
  owners                        = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application" "aad_mgmt_app" {
  count             = var.isInAutomation ? 0 : 1
  display_name      = "infoasst_mgmt_access_${var.randomString}"
  owners            = [data.azurerm_client_config.current.object_id]
  sign_in_audience  = "AzureADMyOrg"
  service_management_reference = var.serviceManagementReference
}

resource "azuread_application_password" "aad_mgmt_app_password" {
  count           = var.isInAutomation ? 0 : 1
  application_id  = azuread_application.aad_mgmt_app[0].id
  display_name    = "infoasst-mgmt"
}

resource "azuread_service_principal" "aad_mgmt_sp" {
  count     = var.isInAutomation ? 0 : 1
  client_id = azuread_application.aad_mgmt_app[0].client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

output "azure_ad_web_app_client_id" {
  value       = var.isInAutomation ? var.aadWebClientId : azuread_application.aad_web_app[0].client_id
  description = "Client ID of the Azure AD Web App"
}

output "azure_ad_mgmt_app_client_id" {
  value       = var.isInAutomation ? var.aadMgmtClientId : azuread_application.aad_mgmt_app[0].client_id
  description = "Client ID of the Azure AD Management App"
}

output "azure_ad_mgmt_sp_id" {
  value       = var.isInAutomation ? var.aadMgmtServicePrincipalId : azuread_service_principal.aad_mgmt_sp[0].id
  description = "Service Principal ID of the Azure AD Management App"
}

output "azure_ad_mgmt_app_secret" {
  value       = var.isInAutomation ? var.aadMgmtClientSecret : azuread_application_password.aad_mgmt_app_password[0].value
  description = "Secret of the Azure AD Management App"
}
