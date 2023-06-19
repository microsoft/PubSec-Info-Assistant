# Setting up Azure DevOps CI/CD Pipeline for setting up Sandbox Environment

To set up an Azure DevOps CI/CD pipeline for deploying code from a GitHub repository, follow these steps:

1. **Create a new Azure DevOps project:** Sign in to your Azure DevOps account and create a new project. Give it a meaningful name and choose the appropriate version control option (Git).

2. **Connect Azure DevOps to GitHub:** In your Azure DevOps project, navigate to **Project Settings** and select **GitHub Connections**. Follow the prompts to authenticate and connect your Azure DevOps account with your GitHub account.

3. **Create a new pipeline:** In your Azure DevOps project, go to **Pipelines** and click on **New Pipeline**. Select **GitHub** as the source repository.

4. **Select your repository:** Choose the GitHub repository [PubSec-Info-Assistant](https://github.com/microsoft/PubSec-Info-Assistant)

5. **Configure your pipeline:** Azure DevOps provides a visual editor for configuring pipelines. Select **Existing Azure Pipelines YAML file**

    ![pipeline_configuration](/docs/images/sandbox_environment_build_pipeline_configuration.png)

6. **Define your build steps:** In the pipeline configuration, steps for building sandbox environment already defined

7. **Configure continuous integration (CI):**  CI trigger has been turned off, need to be triggered manually  start the pipeline to build the sandbox environment. 

8. **Add deployment stages:** In this sandbox environment setup, there is option to select red/blue deployment which represents an environment (e.g., development, staging), and you can define specific tasks for deploying your code to those environments.

9. **Configure variables :** To Configure the deployment, please add below variables to the build pipeline and save the varibles.

    > AZURE_OPENAI_CHATGPT_DEPLOYMENT = gpt-35-turbo \
    > AZURE_OPENAI_GPT_DEPLOYMENT = text-davinci-003 \
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

10. **Save and run the pipeline:** After updating the variable, save your pipeline configuration, review the settings, and click on **Run** to start the pipeline manually for the first time.

11. **Monitor your pipeline:** Azure DevOps provides detailed logs and reports for your pipeline runs. Monitor the execution, review any issues or failures, and iterate on your pipeline configuration as needed.

> Remember that these steps provide a general outline, and you may need to make adjustments based on your specific project and deployment targets. The Azure DevOps documentation provides detailed guides and tutorials for setting up CI/CD pipelines with different tools and scenarios.