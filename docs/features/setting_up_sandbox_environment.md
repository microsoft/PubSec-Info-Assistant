# Setting up Azure DevOps CI/CD Pipeline for setting up Sandbox Environment

The process of setting up a CI/CD pipeline for the Information Assistant Accelerator requires the use of Azure DevOps to host and run the pipeline and deployment environment.

This process involves:

- Setting up an Azure DevOps project
- Configuring an Azure DevOps pipeline
- Configuring Azure Active Directory Objects
- Running and testing the Azure DevOps pipeline

## Setting up an Azure DevOps Project

The CI/CD pipeline process for Information Assistant requires the use of an Azure DevOps project. Follow these steps to set up your Azure DevOps project:

1. **Create a new Azure DevOps project:** Sign in to your Azure DevOps account and create a new project. Give it a meaningful name and choose the appropriate version control option (Git).

2. **Connect Azure DevOps to GitHub:** In your Azure DevOps project, navigate to **Project Settings** and select **GitHub Connections**. Follow the prompts to authenticate and connect your Azure DevOps account with your GitHub account.

## Configuring an Azure DevOps Pipeline

To set up an Azure DevOps CI/CD pipeline for deploying code from a GitHub repository, follow these steps:

1. **Create a new pipeline:** In your Azure DevOps project, go to **Pipelines** and click on **New Pipeline**.

   1. Select **GitHub** as the source repository.

   2. **Select your repository:** Choose the GitHub repository where you have forked the [PubSec-Info-Assistant](https://github.com/microsoft/PubSec-Info-Assistant) repo to.

   3. Under **Configure your pipeline:** select **Existing Azure Pipelines YAML file**

      ![pipeline_configuration](./docs/images/sandbox_environment_build_pipeline_configuration.png)

   4. In the popup window, Select the branch you wish to pull the pipeline definition from. Then select the path at `/pipelines/demo.yml`

   5. Finally **Review your pipeline YAML** to ensure it is what you want.

       1. In the provided pipeline configuration, steps for building sandbox environment are already defined

       2. **Configure continuous integration (CI):**  CI trigger has been turned off, requiring the pipeline to be triggered manually.

       3. **Add deployment stages:** In this sandbox environment setup, there is option to select red/blue deployment which represents an environment (e.g., development, staging) and you can define specific tasks for deploying your code to those environments.

   6. Next **Configure variables :** To Configure the deployment, please add the following variables to the build pipeline and populate with values for your target Azure subscription. Then save the pipeline variables.

       > AZURE_OPENAI_CHATGPT_DEPLOYMENT = gpt-35-turbo \
       > AZURE_OPENAI_SERVICE_KEY = "" \
       > AZURE_OPENAI_SERVICE_NAME = "" \
       > AZURE_STORAGE_ACCOUNT = "" \
       > AZURE_STORAGE_ACCOUNT_KEY = "" \
       > CLIENT_ID = "" \
       > CLIENT_SECRET = "" \
       > CONTAINER_REGISTRY_ADDRESS = "" \
       > SERVICE_PRINCIPAL_ID = "" \
       > TENANT_ID = "" \
       > SUBSCRIPTION_ID = ""

2. **Save and pipeline:** After updating the variable, save your pipeline configuration.

## Configuring Azure Active Directory Objects

The CI/CD pipelines run under a "Service Connection" that leverages an Azure Active Directory Service Principal. This Service Principal will not have rights to create additional Azure Active Directory objects. This requires an Administrative user to manually create the objects before running the pipeline. Follow these steps to configure the Azure AD Objects:

1. In a **Terminal** Window from your DevOps CodeSpace for Information Assistant, log into Azure using the `az login` command.

2. Navigate to the `/scripts` folder and run the `create-ad-objs-for-deployment.sh` script manually.

   - The script will prompt for the following parameters:

        Parameter | Definition
        ---|---
        WORKSPACE |This will need to be the same value used in the .env file for your pipeline deployment.
        Azure Storage Account Name | This will be an Azure Storage Account where the CI/CD state files will be store for automation pipelines.
        Azure Storage Account Key | Provide one of the Administrative keys for the Azure Storage Account specified above.
        Enforce security assignment for the website | Use this setting to determine whether a user needs to be granted explicit access to the website via an Azure AD Enterprise Application membership (true) or allow the website to be available to anyone in the Azure tenant (false). Defaults to false. If set to true, A tenant level administrator will be required to grant the implicit grant workflow for the Azure AD App Registration manually.

    ``` bash
    cd scripts
    bash create-ad-objs-for-deployment.sh

    Please enter your WORKSPACE:
    Please enter the Azure Storage Account for CI/CD State management:
    Please enter the Azure Storage Account Key for CI/CD State management:
    Would you like users to have to be explicitly assigned to the app? (y/n):
      ____                _            _    ____  
     / ___|_ __ ___  __ _| |_ ___     / \  |  _ \ 
    | |   | '__/ _ \/ _` | __/ _ \   / _ \ | | | |
    | |___| | |  __/ (_| | ||  __/  / ___ \| |_| |
     \____|_|  \___|\__,_|\__\___| /_/   \_\____/ 

      ___  _     _           _       
     / _ \| |__ (_) ___  ___| |_ ___ 
    | | | | '_ \| |/ _ \/ __| __/ __|
    | |_| | |_) | |  __/ (__| |_\__ \
     \___/|_.__// |\___|\___|\__|___/
              |__/                   
    ```

## Running and testing the Azure DevOps pipeline

Once you have set up the pipeline configuration and the Azure AD objects you are ready to start the pipeline manually for the first time.

1. Open the pipeline in Azure DevOps and click on **Run**.

2. **Monitor your pipeline:** Azure DevOps provides detailed logs and reports for your pipeline runs. Monitor the execution, review any issues or failures, and iterate on your pipeline configuration as needed.

> Remember that these steps provide a general outline, and you may need to make adjustments based on your specific project and deployment targets. The [Azure DevOps documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/customize-pipeline?view=azure-devops) provides detailed guides and tutorials for setting up CI/CD pipelines with different tools and scenarios.
