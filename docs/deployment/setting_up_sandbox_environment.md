# Setting up Azure DevOps Pipeline for deploying Sandbox Environment

The process of setting up a CI/CD pipeline for the Information Assistant agent template requires the use of Azure DevOps to host and run the pipeline and deployment environment.

An example process involves:

:warning: The provided example pipelines will deploy an instance of the Information Assistant Accelerator, but it is not fully functional without manual changes to the pipeline. The types of changes are covered in the [Configuring Azure Entra Objects](#configuring-azure-entra-objects) section.

- Setting up an Azure DevOps project
- Configuring an Azure DevOps pipeline
- Manually Configuring Azure Entra Objects
- Running and testing the Azure DevOps pipeline

## Setting up an Azure DevOps Project

The Azure DevOps pipeline process for Information Assistant requires the use of an Azure DevOps project. Follow these steps to set up your Azure DevOps project:

1. **Create a new Azure DevOps project:** Sign in to your Azure DevOps account and create a new project. Give it a meaningful name and choose the appropriate version control option (Git).

2. **Connect Azure DevOps to GitHub:** In your Azure DevOps project, navigate to **Project Settings** and select **GitHub Connections**. Follow the prompts to authenticate and connect your Azure DevOps account with your GitHub account.

## Configuring an Azure DevOps Pipeline

To set up an Azure DevOps pipeline for deploying code from a GitHub repository, follow these steps:

1. **Create a new pipeline:** In your Azure DevOps project, go to **Pipelines** and click on **New Pipeline**.

   1. Select **GitHub** as the source repository.

   2. **Select your repository:** Choose the GitHub repository where you have forked the [PubSec-Info-Assistant](https://github.com/microsoft/PubSec-Info-Assistant) repo to.

   3. Under **Configure your pipeline:** select **Existing Azure Pipelines YAML file**

      ![pipeline_configuration](/docs/images/sandbox_environment_build_pipeline_configuration.png)

   4. In the popup window, Select the branch you wish to pull the pipeline definition from. Then select the path at `/pipelines/demo.yml`

   5. Finally **Review your pipeline YAML** to ensure it is what you want.

       1. In the provided pipeline configuration, steps for building sandbox environment are already defined

       2. **Configure continuous integration (CI):**  CI trigger has been turned off, requiring the pipeline to be triggered manually.

       3. **Add deployment stages:** In this sandbox environment setup, there is option to select red/blue deployment which represents an environment (e.g., development, staging) and you can define specific tasks for deploying your code to those environments.

   6. Next **Configure variables :** To Configure the deployment, please add the following variables to the build pipeline and populate with values for your target Azure subscription. Then save the pipeline variables.

   :warning: These are the variables required for the example pipelines provided. You may require additional variables to deploy a fully functioning Information Assistant deployment. Use of Azure DevOps pipeline variable assist in preventing secrets, keys, and other sensitive information from being included in the source tree. 

    VARIABLE | DESCRIPTION
    ---|---
    CLIENT_ID<br />CLIENT_SECRET<br />SERVICE_PRINCIPAL_ID | These are used for the deployment scripts to login to Azure. This is typically a service principal and will need Contributor and User Access Administrator roles.
    SUBSCRIPTION_ID | The ID of the subscription that should be deployed to.
    TENANT_ID | The ID of the tenant that should be deployed to.
    CONTAINER_REGISTRY_ADDRESS | Azure Container Registry where the Info Assistant development container will be cached during pipeline runs
    AZURE_OPENAI_SERVICE_NAME<br/>AZURE_OPENAI_SERVICE_KEY<br/>AZURE_OPENAI_CHATGPT_DEPLOYMENT<br/>AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT_NAME | It is recommended to point the pipeline to an existing installation of Azure OpenAI. These values will be used to target that instance.
    environment | The environment name that matches an environment variable file located in `./scripts/environments`. For example if the pipeline parameter is set to "demo" there needs to be a corresponding file at `/scripts/environment/demo.env`
    TF_BACKEND_ACCESS_KEY | Terraform is used to create Infrastructure as Code. This is the key to the Terraform State in a Storage Account.
    TF_BACKEND_CONTAINER | Terraform is used to create Infrastructure as Code. This is the container that the Terraform State is stored within a Storage Account.
    TF_BACKEND_RESOURCE_GROUP | Terraform is used to create Infrastructure as Code. This is the resource group that the Terraform State is stored within a Storage Account.
    TF_BACKEND_STORAGE_ACCOUNT | Terraform is used to create Infrastructure as Code. This is the storage account that the Terraform State is stored.

2. **Save your pipeline:** After updating the variable, save your pipeline configuration.

## Configuring Azure Entra Objects

The Azure DevOps pipelines run under a "Service Connection" that leverages an Azure Entra Service Principal (the CLIENT_ID and SERVICE_PRINCIPAL_ID parameters above). This Service Principal will not have rights to create additional Azure Entra objects, so an Administrative user needs to manually create the Azure Entra objects required for the Information Assistant environment before running the pipeline. Information on the Azure Entra objects required can be found in our [Manual App Registration Creation Guide](docs/deployment/manual_app_registration.md) and [GitHub Discussion #457](https://github.com/microsoft/PubSec-Info-Assistant/discussions/457)

:warning: The provided example Azure DevOps pipeline currently does NOT configure the accelerator to use the custom Azure Entra objects on when deploying an environment as they are not required for running the functional tests. The example pipelines will need to be extended to apply the custom Azure Entra objects to deploy a fully functioning Information Assistant environment.

## Running and testing the Azure DevOps pipeline

Once you have set up the pipeline configuration and the Azure Entra objects you are ready to start the pipeline manually for the first time.

1. Open the pipeline in Azure DevOps and click on **Run**.

2. **Monitor your pipeline:** Azure DevOps provides detailed logs and reports for your pipeline runs. Monitor the execution, review any issues or failures, and iterate on your pipeline configuration as needed.

> Remember that these steps provide a general outline, and you may need to make adjustments based on your specific project and deployment targets. The [Azure DevOps documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/customize-pipeline?view=azure-devops) provides detailed guides and tutorials for setting up CI/CD pipelines with different tools and scenarios.
