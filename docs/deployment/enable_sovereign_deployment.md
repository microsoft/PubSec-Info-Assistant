# Enable Sovereign Region Deployment

Follow these steps to enable a Sovereign region deployment.  If you need access to Azure OpenAI service in a UsGov region please fill out this form <https://aka.ms/AOAIgovaccess>.

Model availability varies by region and could. For Azure Government model availability, please refer to: <https://learn.microsoft.com/azure/ai-services/openai/azure-government#azure-openai-models>

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
   export USE_WEB_CHAT=false
   ```

4. Consider setting **CHAT_WARNING_BANNER_TEXT**  with `DEV / UNCLASSIFIED / NO CUI` or something similar if deployment is IL2.
