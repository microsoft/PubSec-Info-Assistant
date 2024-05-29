# App Registration Creation Guide

If you are unable to obtain the permission at the tenant level described in [Azure account requirements](https://github.com/microsoft/PubSec-Info-Assistant/tree/v1.0?tab=readme-ov-file#azure-account-requirements), then this guide will provide a manual workaround for you.

## Tenant Administrator: Manual Steps to create App Registrations

Here are the details of each step:

### Create a Random Sequence File
Manually create a random string for your environment. This ensures unique service names to avoid DNS conflicts.

1. In VSCode, open the `/infra` folder.
2. Create a new subfolder named `.state`.
3. Create a new subfolder under the `.state` folder. This folder MUST have the same value as the **WORKSPACE** parameter in the `local.env` file.
4. In that new folder, create a text file named `random.txt`.
5. Edit the TXT file and enter a 1 to 5 character sequence. The value must be a combination of letters a-z, A-Z, or numbers 0-9.

### Have Administrator Create Two AD App Registrations and Enterprise Applications
An Administrator in the tenant would need to create two Azure AD App Registrations and Service Principals for you manually.

#### First AD App Registration: Securing the Information Assistant Web Application
The first AD App Registration will be used to secure the Information Assistant web application and will need to ensure the following settings:

**Azure AD App Registration**
| Setting | Value |
|---|---|
| name | `infoasst_web_access_<<random_string_from_above>>` |
| sign-in-audience | AzureADMyOrg |
| identifier-uris | `api://infoasst-<<random_string_from_above>>` |
| web-redirect-uris | `https://infoasst-web-<<random_string_from_above>>.azurewebsites.net/.auth/login/aad/callback` |
| enable-access-token-issuance | true |
| enable-id-token-issuance | true |

**Azure AD Enterprise Application (optional)**
If you desire to have the Information Assistant website secured by explicit membership, then the following settings will need to be updated:

| Setting | Value |
|---|---|
| name | `infoasst_web_access_<<random_string_from_above>>` |
| appRoleAssignmentRequired | true |

#### Second AD App Registration: Querying Azure Management Plane APIs
The second AD App Registration will be used to query the Azure management plane APIs for Azure service details. It needs the following settings:

**Azure AD App Registration**
| Setting | Value |
|---|---|
| name | `infoasst_mgmt_access_<<random_string_from_above>>` |
| sign-in-audience | AzureADMyOrg |

### Information to Obtain from Tenant Administrator
You will need to obtain the following information from your tenant Administrator to continue:
- Web Access App Registration Client ID (guid)
- Web Access Service Principal ID (guid)
- Management Access App Registration Client ID (guid)
- Management Access App Registration Client Secret
- Management Access Service Principal ID (guid)

### Adjust Code in Infrastructure Deployment
In the file `scripts/inf-create.sh`, between lines 97 - 138, you would need to replace the code with the following sample. Update parameters with values provided by your tenant Administrator.

```bash
signedInUserId=$(az ad signed-in-user show --query id --output tsv)
kvAccessObjectId=$signedInUserId
aadWebAppId=<web access client id>
aadWebSPId=<web access service principal id>
aadMgmtAppId=<mgmt access client id>
aadMgmtAppSecret=<mgmt access client secret>
aadMgmtSPId=<mgmt access service principal id>

# Rest of your script continues...
