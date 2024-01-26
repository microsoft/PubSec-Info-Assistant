


resource "azuread_application" "aad_web_app" {
  display_name                       = "infoasst_web_access_${var.randomString}"
  sign_in_audience           = "AzureADMyOrg"
  identifier_uris            = ["api://infoasst-${var.randomString}"]
  web { 
    redirect_uris        = ["https://infoasst-web-${var.randomString}.${var.webAppSuffix}/.auth/login/aad/callback"] 
    }
    
}



resource "azuread_service_principal" "aad_web_sp" {
  client_id = azuread_application.aad_web_app.application_id
}


resource "azuread_application" "aad_mgmt_app" {
  display_name = "infoasst_mgmt_access_${var.randomString}"
}

resource "azuread_application_password" "aad_mgmt_app_password" {
  application_id = azuread_application.aad_mgmt_app.id
}

resource "azuread_service_principal" "aad_mgmt_sp" {
  client_id = azuread_application.aad_mgmt_app.application_id
}

resource "azuread_service_principal" "aad_web_app_update" {
  count = var.requireWebsiteSecurityMembership ? 1 : 0

  client_id = azuread_application.aad_web_app.id
  app_role_assignment_required = true
}









# output "signed_in_user_principal" {
#   value       = azuread_signed_in_user.signed_in_user.id
#   description = "ID of the signed-in user"
# }

output "azure_ad_web_app_client_id" {
  value       = azuread_application.aad_web_app.application_id
  description = "Client ID of the Azure AD Web App"
}

output "azure_ad_mgmt_app_client_id" {
  value       = azuread_application.aad_mgmt_app.application_id
  description = "Client ID of the Azure AD Management App"
}

output "azure_ad_mgmt_sp_id" {
  value       = azuread_service_principal.aad_mgmt_sp.id
  description = "Service Principal ID of the Azure AD Management App"
}

output "azure_ad_mgmt_app_secret" {
  value       = azuread_application_password.aad_mgmt_app_password.value
  description = "Secret of the Azure AD Management App"
}
