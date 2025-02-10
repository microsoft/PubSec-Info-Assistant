output "azure_ad_web_app_client_id" {
  value       = var.useCustomEntra ? var.aadWebClientId : azuread_application.aad_web_app[0].client_id
  description = "Client ID of the Azure AD Web App"
}

output "azure_ad_mgmt_app_client_id" {
  value       = var.useCustomEntra ? var.aadMgmtClientId : azuread_application.aad_mgmt_app[0].client_id
  description = "Client ID of the Azure AD Management App"
}

output "azure_ad_mgmt_sp_id" {
  value       = var.useCustomEntra ? var.aadMgmtServicePrincipalId : azuread_service_principal.aad_mgmt_sp[0].object_id
  description = "Service Principal ID of the Azure AD Management App"
}