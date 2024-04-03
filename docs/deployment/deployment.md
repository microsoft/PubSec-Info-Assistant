# Deploying IA Accelerator to Azure

:warning: **IMPORTANT**: Please ensure you have met the [Azure account requirements](../../README.md#azure-account-requirements) before continuing.

Follow these steps to get the accelerator up and running in a subscription of your choice. Note that there may be specific instructions for deploying to Azure Government or other Sovereign regions.

If you prefer to have a more guided experience, you may choose to [view the click-through deployment guide](https://aka.ms/InfoAssist/deploy) for this accelerator.  

## Development Environment Configuration

The deployment process for the IA Accelerator, uses a concept of **Developing inside a Container** to containerize all the necessary pre-requisite component without requiring them to be installed on the local machine. The environment you will work in will be created using a development container or dev container hosted on a virtual machine using GitHub Codespaces.

Begin by first forking the Information Assistant repository into your own repository. This can be useful for managing any changes you may require for your local environment. It will also enable you to accept and merge changes from the Information Assistant repo as future releases and hotfixes are made available.

To fork the repo simply click the **Fork** button at the top of the Information Assistant Repo page and follow the steps to set up your new fork.
![Fork the Information Assistant Repo](/docs/images/fork_repo.png)

Once you have forked the repo, you can then use the following button to open the Information Assistant GitHub Codespaces. You will need to select your forked repo and the location for your GitHub Codespaces to run in.

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://github.com/codespaces/new?hide_repo_select=false&ref=main&machine=basicLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json)

Begin by setting up your own GitHub Codespaces using our  [Developing in Codespaces](/docs/deployment/developing_in_a_GitHub_Codespaces.md) documentation.

*If you want to configure your local desktop for development container or you do not have access to GitHub Codespaces, follow our [Configuring your System for Development Containers](/docs/deployment/configure_local_dev_environment.md) guide. More information can be found at [Developing inside a Container](https://code.visualstudio.com/docs/remote/containers).*

Once you have the completed setting up a GitHub Codespaces, please move on to the Sizing Estimation step.

## Sizing Estimator

 The IA Accelerator needs to be sized appropriately based on your use case. Please review our [Sizing Estimator](/docs/costestimator.md) to help find the configuration that fits your needs.

 To change the size of components deployed, make changes in the [Main Bicep](/infra/main.bicep) file.

Once you have completed the Sizing Estimator and sized your deployment appropriately, please move on to the Configuring your Environment step.

## Configure ENV files

You now need to set up your local environment variables file in preparation for deployment.

Inside your Development environment (GitHub Codespaces or Container), do the following:

>1. Open `scripts/environments` and copy `local.env.example` to `local.env`.
>1. Then open `local.env` and update values as needed:

Variable | Required | Description
--- | --- | ---
LOCATION | Yes | The location (West Europe is the default). The BICEP templates use this value. To get a list of all the current Azure regions you can run `az account list-locations -o table`. The value here needs to be the *Name* value and not *Display Name*.
WORKSPACE | Yes  | The workspace name (use something simple and unique to you). This will appended to infoasst-????? as the name of the resource group created in your subscription.
SUBSCRIPTION_ID | Yes | The GUID that represents the Azure Subscription you want the Accelerator to be deployed into. This can be obtained from the *Subscription* blade in the Azure Portal.
TENANT_ID | Yes | The GUID that represents the Azure Active Directory Tenant for the Subscription you want the accelerator to be deployed into. This can be obtained from the *Tenant Info* blade in the Azure Portal.
AZURE_ENVIRONMENT | Yes | This will determine the Azure cloud environment the deployment will target. Information Assistant currently supports, AzureCloud and AzureUSGovernment. Info available at [Azure cloud environments](https://docs.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli?toc=/cli/azure/toc.json&bc=/cli/azure/breadcrumb/toc.json). If you are targeting "AzureUSGovernment" please see our [sovereign deployment support documentation](/docs/deployment/enable_sovereign_deployment.md).
SECURE_MODE | Yes | Defaults to `false`. This feature flag will determine if the Information Assistant deploys it's Azure Infrastructure in a secure mode or not.</br>:warning: Before enabling secure mode please read the extra instructions on [Enabling Secure Deployment](#tdb)
ENABLE_WEB_CHAT | Yes | Defaults to `false`. This feature flag will enable the ability to use Web Search results as a data source for generating answers from the LLM. This feature will also deploy a Bing v7 Search instance in Azure to retrieve web results from, however Bing v7 Search is not available in AzureUSGovernment regions, so this feature flag is **NOT** compatible with `AZURE_ENVIRONMENT=AzureUSGovernment`.
ENABLE_BING_SAFE_SEARCH | No | Defaults to `true`. If you are using the `ENABLE_WEB_CHAT`feature you can set the following values to enable safe search on the Bing v7 Search APIs.
ENABLE_UNGROUNDED_CHAT | Defaults to `false`. This feature flag will enable the ability to interact directly with an LLM. This experience will be similar to the Azure OpenAI Playground.
ENABLE_MATH_ASSISTANT | Yes | Defaults to `true`. This feature flag will enable the Math Assistant tab in the Information Assistant website. Read more information on the [Math Assistant](/docs/features/features.md) 
ENABLE_TABULAR_DATA_ASSISTANT | Yes | Defaults to `true`. This feature flag will enable the Tabular Data Assistant tab in the Information Assistant website. Read more information about the [Tabular Data Assistant](/docs/features/features.md)
ENABLE_SHAREPOINT_CONNECTOR | Yes | Defaults to `false`. This feature flag enabled the ability to ingest data from SharePoint document stores into the Information Assistant. When enabled, be sure to set the `SHAREPOINT_TO_SYNC` parameter for your SharePoint sites. Read more about configuring the [SharePoint Connector](/docs/features/sharepoint.md) 
SHAREPOINT_TO_SYNC | No | This is a JSON Array of Objects for SharePoint Sites and their entry folders. The app will crawl down from the folder specified for each site. Specifying "/Shared Documents" will crawl all the documents in your SharePoint. `[{"url": "https://SharePoint.com/", "folder": "/Shared Documents"}]` Information on setting up SharePoint Ingestion can be found here [SharePoint Connector](/docs/features/sharepoint.md)
ENABLE_MULTIMEDIA | Yes | Defaults to `false`. This feature flag should not be changed at this time. The multimedia feature is still in development. Enabling this feature will deploy an Azure Video Indexer instance in your resource group only. 
REQUIRE_WEBSITE_SECURITY_MEMBERSHIP | Yes | Use this setting to determine whether a user needs to be granted explicit access to the website via an Azure AD Enterprise Application membership (true) or allow the website to be available to anyone in the Azure tenant (false). Defaults to false. If set to true, A tenant level administrator will be required to grant the implicit grant workflow for the Azure AD App Registration manually.
SKIP_PLAN_CHECK | No | If this value is set to 1, then the BICEP deployment will not stop to allow you to review the planned changes. The default value is 0 in the scripts, which will allow the deployment to stop and confirm you accept the proposed changes before continuing.
USE_EXISTING_AOAI | Yes | Defaults to false. Set this value to "true" if you want to use an existing Azure Open AI service instance in your subscription. This can be useful when there are limits to the number of AOAI instances you can have in one subscription. When the value is set to "false" and BICEP will create a new Azure Open AI service instance in your resource group.
AZURE_OPENAI_RESOURCE_GROUP | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of the resource group that hosts the Azure Open AI service instance in your subscription.
AZURE_OPENAI_SERVICE_NAME | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of the Azure Open AI service instance in your subscription.
AZURE_OPENAI_SERVICE_KEY | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the Key for the Azure Open AI service instance in your subscription.
AZURE_OPENAI_CHATGPT_DEPLOYMENT | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of a deployment of the "gpt-35-turbo" model in the Azure Open AI service instance in your subscription.
USE_AZURE_OPENAI_EMBEDDINGS | Yes | Defaults to "true". When set to "true" this value indicates to Information Assistant to use Azure OpenAI models for embedding text values. If set to "false", Information Assistant will use the open source language model that is provided in the values below.
AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME| No | If you have set **USE_AZURE_OPENAI_EMBEDDINGS** to "true" then use this parameter to provide the name of a deployment of the "text-embedding-ada-002" model in the Azure Open AI service instance in your subscription.
OPEN_SOURCE_EMBEDDING_MODEL | No | A valid open source language model that Information Assistant will use for text embeddings. The model needs to be downloadable and available through Sentence Transformer. This setting will be used when **USE_AZURE_OPENAI_EMBEDDINGS** is set to "false".
OPEN_SOURCE_EMBEDDING_MODEL_VECTOR_SIZE | No | When specifying an open source language model the vector size the model's embedding produces must be specified so that the Azure AI Search hybrid index's vector columns can be set to the matching size. This setting will be used when **USE_AZURE_OPENAI_EMBEDDINGS** is set to "false".
AZURE_OPENAI_CHATGPT_MODEL_NAME | No | This can be used to select a different GPT model to be deployed to Azure OpenAI when the default (gpt-35-turbo-16k) isn't available to you.
AZURE_OPENAI_CHATGPT_MODEL_VERSION | No | This can be used to select a specific version of the GPT model above when the default (0613) isn't available to you.
AZURE_OPENAI_EMBEDDINGS_MODEL_NAME | No | This will display in the Info panel in the UX if you don't have access to the resource group where the Azure OpenAI embeddings models are deployed. See *local.env.example* for specific guidance.
AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION | No | This will display in the Info panel in the UX if you don't have access to the resource group where the Azure OpenAI embeddings models are deployed. See *local.env.example* for specific guidance.
AZURE_OPENAI_CHATGPT_MODEL_CAPACITY | Yes | This value can be used to provide the provisioned capacity of the GPT model deployed to Azure OpenAI when you have reduced capacity.
AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY | Yes | This value can be used to provide the provisioned capacity of the embeddings model deployed to Azure OpenAI.
CHAT_WARNING_BANNER_TEXT | No | Defaults to "". Provide a value in this parameter to display a header and footer to the UX of Information Assistant with the included warning banner text.
DEFAULT_LANGUAGE | Yes | Use the parameter to specify the matching ENV file located in the `scripts/environments/languages` folder. You can then use this file to customize the language settings of the search index, search skillsets, and Azure OpenAI prompts. See [Configuring your own language ENV file](/docs/features/configuring_language_env_files.md) more information.
ENABLE_CUSTOMER_USAGE_ATTRIBUTION <br>CUSTOMER_USAGE_ATTRIBUTION_ID | No | By default, **ENABLE_CUSTOMER_USAGE_ATTRIBUTION** is set to `true`. The CUA GUID which is pre-configured will tell Microsoft about the usage of this software. Please see [Data Collection Notice](/README.md#data-collection-notice) for more information. <br/><br/>You may provide your own CUA GUID by changing the value in **CUSTOMER_USAGE_ATTRIBUTION_ID**. Ensure you understand how to properly notify your customers by reading <https://learn.microsoft.com/en-us/partner-center/marketplace/azure-partner-customer-usage-attribution#notify-your-customers>.<br/><br/>To disable data collection, set **ENABLE_CUSTOMER_USAGE_ATTRIBUTION** to `false`.
ENABLE_DEV_CODE | No | Defaults to `false`. It is not recommended to enable this flag, it is for development testing scenarios only.
APPLICATION_TITLE | No | Defaults to "". Providing a value for this parameter will replace the Information Assistant's title in the black banner at the top of the UX.

## Log into Azure using the Azure CLI

You can use the bash prompt in your GitHub Codespaces to issue the following commands:

``` bash
    az login
```

This will launch a browser session where you can complete you login. If you get an error on this step, we suggest you use the device code option for login.

> **NOTICE:** if your organization requires managed devices, ensure that you are running the GitHub Codespaces from your managed device's VS Code installation. For more information, please see the [Developing in a Codespace](/docs/developing_in_a_codespaces.md#opening-a-codespace-in-vs-code) documentation.

Next from the bash prompt run:

``` bash
    az account show
```

The output here should show that you're logged into the intended Azure subscription.  If this isn't showing the right subscription then you can list all the subscriptions you have access to with:

``` bash
    az account list
```

From this output, grab the Subscription ID of the subscription you intend to deploy to and run:

``` bash
    az account set --subscription mysubscriptionID
```

## Deploy and Configure Azure resources

Now that your GitHub Codespaces/Container and ENV files are configured, it is time to deploy the Azure resources. This is done using a `Makefile`.

To deploy everything run the following command from the GitHub Codespaces/Dev Container prompt:

```bash
    make deploy
```

This will deploy the infrastructure and the application code.

*This command can be run as many times as needed in the event you encounter any errors. A set of known issues and their workarounds that we have found can be found in [Known Issues](/docs/knownissues.md)*

### Additional Information

For a full set of Makefile rules, run `make help`.

``` bash
vscode ➜ /workspaces/<accelerator> (main ✗) $ make help
help                         Show this help
deploy                       Deploy infrastructure and application code
build                        Build application code
infrastructure               Deploy infrastructure
extract-env                  Extract infrastructure.env file from BICEP output
deploy-webapp                Deploys the web app code to Azure App Service
deploy-functions             Deploys the function code to Azure Function Host
deploy-enrichments           Deploys the web app code to Azure App Service
deploy-search-indexes        Deploy search indexes
extract-env-debug-webapp     Extract infrastructure.debug.env file from BICEP output
extract-env-debug-functions  Extract local.settings.json to debug functions from BICEP output
functional-tests             Run functional tests to check the processing pipeline is working
```

## Configure authentication and authorization

If you have chosen to enable authentication and authorization for your deployment by setting the environment variable `REQUIRE_WEBSITE_SECURITY_MEMBERSHIP` to `true`, you will need to configure it at this point. Please see [Known Issues](/docs/knownissues.md#error-your-adminstrator-has-configured-the-application-infoasst_web_access_xxxxx-to-block-users) section for guidance on how to configure.

**NOTICE:** If you haven't enabled this, but your Tenant requires this, you may still need to configure as noted above.

## Authorizing SharePoint

1. Go to your resource group in the [Azure Portal](https://portal.azure.com/), select the "sharepointonline" API Connection resource.
2. Click "Edit API Connection" in the menu on the left side of your screen.
3. Click "Authorize" and login with the user that has access to the SharePoint sites you put in your environment file. It is **strongly** recommended that you have created a new user for this purpose.
4. After you've done that **click Save**, if you do not click save, you will **NOT** be authorized.
5. Once you're authorized, you may manually run the logic app (see below) or wait 24 hours for it to automatically run.

More information about SharePoint can be found here [SharePoint Feature](/docs/features/sharepoint.md)

**NOTICE:** You do not need to do this step if you are not using the SharePoint for Information Assistant

## Find your deployment URL

Once deployed, you can find the URL of your installation by:

1) Browse to your new Resource Group at https://portal.azure.com and locate the "App Service" with the name that starts with "infoasst-web"
![Location of App Service in Portal](/docs/images/deployment_app_service_location.jpg)

2) After clicking on the App Service, you will see the "Default domain" listed. This is the link to your installation.
![Default Domain of App Service in Portal](/docs/images/deployment_default_domain.jpg)

## Next steps

At this point deployment is complete. Please go to the [Using the IA Accelerator for the first time](/docs/deployment/using_ia_first_time.md) section and complete the following steps.


## Additional Considerations for a Production Adoption

There are considerations for adopting the Information Assistant (IA) accelerator into a production environment. [See this documentation](/docs/deployment/considerations_production.md).


## Need Help?

Check these [troubleshotting methods](/docs/deployment/troubleshooting.md).


If you need assistance with deployment or configuration of this accelerator, please leverage the Discussion forum in this repository, or reach out to your Microsoft Unified Support account manager.
