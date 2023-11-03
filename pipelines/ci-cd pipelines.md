## Setting Up The CI/CD pipelines

To get started with setting up your deployment pipelines please take the following steps:

### Azure DevOps Pipelines

1. Create an environment called shared in `Pipelines -> Environments -> New environment`.
2. Create a pipeline in `Pipelines -> Pipelines -> New pipeline`. This should point to the [./pipelines/azdo.yml](./pipelines/azdo.yml) configuration file.
3. Set up the pipeline variables:
    - CLIENT_ID, CLIENT_SECRET, SERVICE_PRINCIPAL_ID: These are used for the deployment scripts to login to Azure. This is typically a service principal and will need Contributor access as a minimum
    - SUBSCRIPTION_ID: The ID of the subscription that should be deployed to.
    - TENANT_ID: The ID of the tenant that should be deployed to.
    - AZURE_STORAGE_ACCOUNT: Bicep is used to create Infrastructure as Code. This is the storage account that the Bicep State is stored.
    - AZURE_STORAGE_ACCOUNT_KEY: Bicep is used to create Infrastructure as Code. This is the storage account access key is used to access the Bicep state file.
    - AZURE_OPENAI_SERVICE_NAME : Is used to provide  access to many different models.
    - AZURE_OPENAI_SERVICE_KEY : These keys are used to access your Cognitive Service API.
    - AZURE_OPENAI_CHATGPT_DEPLOYMENT: These are used for the ChatGPT model (gpt-35-turbo) for conversational interfaces.
    - AZURE_OPENAI_EMBEDDING_MODEL: This specifies the embeddings model deployed and used
    - AD_MGMT_SERVICE_PRINCIPAL_ID: Azure AD Service for your environment
    - AD_MGMTAPP_CLIENT_ID: Azure AD Client Identifier for your environment Service Principal
    - AD_MGMTAPP_CLIENT_SECRET: Azure AD Client Secret for your environment Service Principal
    - CONTAINER_REGISTRY_ADDRESS: ACR host of the Info Assistant development container used by CICD
    - WEBAPP_CLIENT_ID: WebApp Application Registration Identifier
    - environment: Environment variable file. Located in [./scripts/environments](./scripts/environments)
