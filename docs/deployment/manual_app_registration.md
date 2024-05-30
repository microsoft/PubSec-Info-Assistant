# App Registration Creation Guide

If you are unable to obtain the permission at the tenant level described in [Azure account requirements](https://github.com/microsoft/PubSec-Info-Assistant/tree/v1.0?tab=readme-ov-file#azure-account-requirements), you can follow the guidance below to create a manual app registration.

## Tenant Administrator: Manual steps to create app registrations

Here are the details of each step:

### 1. Create a Random Sequence File

Manually create a random string for your environment, which should be a 1 to 5 character sequence. The value must be a combination of letters a-z, A-Z, or numbers 0-9.

### 2. Have the Tenant Administrator Should Create Two AD App Registrations

An Administrator in the tenant would need to create two Azure AD App Registrations and Service Principals for you manually.

#### First AD App Registration: Securing the Information Assistant Web Application

The first AD App Registration will be used to secure the Information Assistant web application and will need to ensure the following settings:

##### Azure AD App Registration**

| Setting | Value |
|---|---|
| name | `infoasst_web_access_<<random_string_from_above>>` |
| sign-in-audience | AzureADMyOrg |
| identifier-uris | `api://infoasst-<<random_string_from_above>>` |
| web-redirect-uris | `https://infoasst-web-<<random_string_from_above>>.azurewebsites.net/.auth/login/aad/callback` |
| enable-access-token-issuance | true |
| enable-id-token-issuance | true |

#### Azure AD Enterprise Application (optional)

If you desire to have the Information Assistant website secured by explicit membership, then the following settings will need to be updated:

| Setting | Value |
|---|---|
| name | `infoasst_web_access_<<random_string_from_above>>` |
| appRoleAssignmentRequired | true |

#### Second AD App Registration: Querying Azure Management Plane APIs

The second AD App Registration will be used to query the Azure management plane APIs for Azure service details. It needs the following settings:

##### Azure AD App Registration

| Setting | Value |
|---|---|
| name | `infoasst_mgmt_access_<<random_string_from_above>>` |
| sign-in-audience | AzureADMyOrg |

### 3.  Information to obtain from Tenant Administrator

You will need to obtain the following information from your tenant Administrator to continue:

- Web Access App Registration Client ID (guid)
- Web Access Service Principal ID (guid)
- Management Access App Registration Client ID (guid)
- Management Access Service Principal ID (guid)
- Management Access App Registration Client Secret (string)

These values will be used to update the code in the infrastructure deployment section.

### 4.  Adjust code in infrastructure deployment

In the file `scripts/inf-create.sh`, between lines 63 - 69, you would need to uncomment the code  and update parameters with values provided by your tenant Administrator.

```
export TF_VAR_isInAutomation=true
export TF_VAR_aadWebClientId=""
export TF_VAR_aadMgmtClientId=""
export TF_VAR_aadMgmtServicePrincipalId=""
export TF_VAR_aadMgmtClientSecret=""
```

### 5. Resume the deployment as per the deployment procedure

After completing the step4, you can resume back the deployment steps mentioned the documentation

### 6: Update the AD App Registration

Once Terraform completes the deployment of the infrastructure, update the `identifier-uris` and `web-redirect-uris` with the newly generated random_string created during the Terraform deployment.
