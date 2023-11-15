# Configure for OAuth Client Credentials Flow using Azure Entra ID

If you want to call the backend API directly or want to use a custom User Interface, you can reconfigure the Web App to use Token Authentication with Client Credentials Flow.
The below directions are showing how to accomplish via portal but most of which could be implemented in existing IaC through Bicep.

## Update App Registration

Navigate to the 'App Registrations' on Microsoft Entra ID and search for your `infoasst-web-xxx`
Save the Client ID and Tenant ID for use later.
Navigate to the 'Expose an API' blade and take note of the value for `Application ID URI`.

Go to 'App Roles' bladeAdd an App Role to the App registration. Could be something to the effect of APIUser for example.

Go to 'API permissions' blade and Add a permission, selecting `infoasst_web_access_xxxx` with Application permissions type and you should see your newly created role to be selected. Add that permision.

## Update Enterprise Application

Navigate to the 'Enterprise applications' on Microsoft Entra ID and search for your `infoasst_web_access_xxxx`
Select the blade option 'Properties' and set 'Assignment Required' to "NO".
Select the 'Permissions' blade and click button to grant admin consent for the enterprise application.

## Reconfigure Web App Authentication

From the Azure portal, navigate to the IA Web app. On the left side select the Authentication blade.
Delete the existing Microsoft Identity Provider and select the popup option to remove authorization.

Once completed, select the option to add a new provider.
Select the Microsoft Provider option with the following options

Tenant Type: Workforce
App Registration: Pick existing app registration in this directory `infoasst-web-xxxx`
Supported Account Types: Current Tenant
Restrict access: Require authentication
Unauthenticated requests: HTTP 401 Unauthorized: recommended for APIs
Token store: Checked

After Saving it will bring you back to the Authentication tab where you will see your newly created Microsoft Identity provider.
Click the Edit icon and add the correct token audience. This value will be the same recorded earlier from the App Registration `Application ID URI`.

After this is completed a new secret will be generated in the 'Certificates and Secrets' blade of the App Registration.
Save this, it should now also exist in the App Service Configuration map 'Application Settings' with key: `MICROSOFT_PROVIDER_AUTHENTICATION_SECRET`

## Test to confirm configuration

You can follow these steps to see the new authentication configured.
Make a rest POST call to login.microsoftonline.com/{your_tenant_id}/oauth2/v2.0/token
With form data parameters:

`grant_type="client_credentials"`
`client_id="<your_app_registration_client_id>"`
`client_secret="<your_app_registration_client_secret>"`
`scope="api://<your_Application_ID_URI>/.default"`

This post call should return a token.

Construct a restful call to the backend api using the Token as a Bearer token Authorization.
On example call could be a GET call to infoasst-web-xxxx.azurewebsites.net/getalluploadstatus
You should see a 200 response with valid configuration.
