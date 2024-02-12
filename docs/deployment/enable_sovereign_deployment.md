# Enable Sovereign Region Deployment

Follow these steps to enable a Sovereign region deployment.  If you need access to AOAI in a UsGov region please fill out this form https://aka.ms/AOAIgovaccess.

Only Sovereign regions supported today are **US Gov Virginia, US Gov Arizona**.

## Setup the environment

To enable a Sovereign region deployment, you need to update the local.env file with the following values

1. Navigate to your `local.env` and update your region to a usgov region:

   ```bash
   export LOCATION="usgovvirginia"
   ```

   or

   ```bash
   export LOCATION="usgovvarizona"
   ```

2. Set **IS_USGOV_DEPLOYMENT** parameter to `true` 

3. Set **USE_EXISTING_AOAI** parameter to `true` if you have a existing AOAI instance deployed.  If you want to create Azure Open AI resource during deployment then set this parameter to `false`

4. If **USE_EXISTING_AOAI** is set to `true` then set the following parameters based on your AOAI deployment:
   *You can find these values from https://oai.azure.us/portal via the Deployments URL.*

   ```bash
   export AZURE_OPENAI_CHATGPT_MODEL_NAME="gpt-35-turbo-16k"
   export AZURE_OPENAI_CHATGPT_MODEL_VERSION="0613"
   export AZURE_OPENAI_EMBEDDINGS_MODEL_NAME="text-embedding-ada-002"
   export AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION="2"
   ```

5. Consider setting **CHAT_WARNING_BANNER_TEXT**  with `DEV / UNCLASSIFIED / NO CUI` or something similar if deployment is IL2.


