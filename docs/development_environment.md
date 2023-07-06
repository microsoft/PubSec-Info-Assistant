# Configure Local Development Environment

Follow these steps to get the accelerator up and running in a subscription of your choice.

### Log into Azure using the Azure CLI

---

You can use the bash prompt in your Codespace to issue the following commands:

``` bash
    az login
```

This will launch a browser session where you can complete you login.

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
    az account set --subscription mysubscription
```

## Configure Dev Container and ENV files

Now that the Codespace is running and logged into Azure, we need to set up your local environment variables. 

1. Open `scripts/environments` and copy `local.env.example` to `local.env`.
1. Then open `local.env` and update values as needed:

Variable | Required | Description
--- | --- | ---
LOCATION | Yes | The location (West Europe is the default). The BICEP templates use this value.
WORKSPACE | Yes  | The workspace name (use something simple and unique to you). This will appended to infoasst-????? in your subscription.
SUBSCRIPTION_ID | Yes | The GUID that represents the Azure Subscription you want the Accelerator to be deployed into.
REQUIRE_WEBSITE_SECURITY_MEMBERSHIP | Yes | Use this setting to determine whether a user needs to be granted explicit access to the website via an Azure AD Enterprise Application membership (true) or allow the website to be available to anyone in the Azure tenant (false). Defaults to false. If set to true, A tenant level administrator will be required to grant the implicit grant workflow for the Azure AD App Registration manually.
SKIP_PLAN_CHECK | No | If this value is set to 1, then the BICEP deployment will not stop to allow you to review the planned changes. The default value is 0 in the scripts, which will allow the deployment to stop and confirm you accept the proposed changes before continuing.
USE_EXISTING_AOAI | Yes | Set this value to "true" if you want to use an existing Azure Open AI service instance in your subscription. This can be useful when there are limits to the number of AOAI instances you can have in one subscription. Set the value to "false" and BICEP will create a new Azure Open AI service instance in your resource group.
AZURE_OPENAI_SERVICE_NAME | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of the Azure Open AI service instance in your subscription.
AZURE_OPENAI_SERVICE_KEY | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the Key for the Azure Open AI service instance in your subscription.
AZURE_OPENAI_GPT_DEPLOYMENT | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of a deployment of the "text-davinci-002" model in the Azure Open AI service instance in your subscription.
AZURE_OPENAI_CHATGPT_DEPLOYMENT | No | If you have set **USE_EXISTING_AOAI** to "true" then use this parameter to provide the name of a deployment of the "gpt-35-turbo" model in the Azure Open AI service instance in your subscription.
DEFAULT_LANGUAGE | Yes | Use the parameter to specify the matching ENV file located in the `scripts/environments/languages` folder. You can then use this file to customize the language settings of the search index, search skillsets, and Azure OpenAI prompts. See [Configuring your own language ENV file](./features/configuring_language_env_files.md) more information.
