# Enable Sovereign Region Deployment

Follow these steps to enable a split deployment.  All resources outside of AOAI will be deployed in an Sovereign region.

Only Sovereign regions supported today are **US Gov**.

## Setup the environment

To enable a Sovereign region deployment, you need to update the local.env file with the following values

1. Navigate to your `local.env` and update your region to a usgov region:

   ```bash
   export LOCATION="usgovvirginia"
   ```

2. Set **IS_USGOV_DEPLOYMENT** parameter to `true` 

3. Set **USE_EXISTING_AOAI** parameter to `true` 

4. Set the following parameters based on your AOAI deployment:
   *You can find these values from https://oai.azure.com/portal via the Deployments URL.*

   ```bash
   export AZURE_OPENAI_CHATGPT_MODEL_NAME="gpt-35-turbo-16k"
   export AZURE_OPENAI_CHATGPT_MODEL_VERSION="0613"
   export AZURE_OPENAI_EMBEDDINGS_MODEL_NAME="text-embedding-ada-002"
   export AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION="2"
   ```

5. Consider setting **CHAT_WARNING_BANNER_TEXT**  with `DEV / UNCLASSIFIED / NO CUI` or something similar if deployment is IL2.


