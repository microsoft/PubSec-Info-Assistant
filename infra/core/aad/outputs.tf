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
