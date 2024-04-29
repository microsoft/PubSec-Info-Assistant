# Enable Sovereign Region Deployment

Follow these steps to enable a Sovereign region deployment.  If you need access to AOAI in a UsGov region please fill out this form <https://aka.ms/AOAIgovaccess>.

Only Sovereign regions / models supported are listed here: <https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#azure-government-regions>

## Setup the environment

To enable a Sovereign region deployment, you need to update the local.env file with the following values

1. Navigate to your `local.env` and update your location to a usgov region:

   ```bash
   export LOCATION="usgovvirginia"
   ```

   or

   ```bash
   export LOCATION="usgovvarizona"
   ```

2. Set **AZURE_ENVIRONMENT** parameter to `AzureUSGovernment`

3. Ensure the following feature flags are disabled as they are not available in US Government deployments.

   ```bash
   export ENABLE_WEB_CHAT=false
   export ENABLE_SHAREPOINT_CONNECTOR=false
   ```

4. Set **USE_EXISTING_AOAI** parameter to `true` if you have a existing AOAI instance deployed.  If you want to create Azure Open AI resource during deployment then set this parameter to `false`

5. Consider setting **CHAT_WARNING_BANNER_TEXT**  with `DEV / UNCLASSIFIED / NO CUI` or something similar if deployment is IL2.
