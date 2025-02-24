# Deployment options for azd

You can customize many features of the Information Assistant agent template by setting azd environment variables. Those variables and their purposes are detailed below:

- [Azure Clouds](#targeting-different-azure-clouds)
- [Info Assistant Feature Flags](#feature-flags)
- [Azure Open AI Resources](#azure-open-ai-resources)
- [Azure Search Service Settings](#azure-search-service-settings)
- [Custom Network Settings](#custom-network-settings)
- [System Language Settings](#system-language-settings)
- [Custom Entra Object Settings](#custom-entra-objects)
- [Security and Expirations](#security-and-expirations)
- [DDOS Protection Plan](#ddos-protection-plan)
- [Data Collection Settings](#data-collection)
- [Store Terraform State in Azure](#store-terraform-state-in-azure)
- [Miscellaneous](#miscellaneous)

## Targeting Different Azure Clouds

By default IA agent template is configured to target Azure Commercial cloud, but can support targeting Azure US Government cloud as well.

To target the US Government cloud run the following commands:

- Run `azd env set AZURE_ENVIRONMENT AzureUSGovernment`

To swich back to Azure Commercial cloud you can run:

- Run `azd env set AZURE_ENVIRONMENT AzureCloud`

## Feature Flags

You can enable or disable features of the IA agent template using the following options:

### Work + Web mode

This feature flag will enable the ability to use Web Search results as a data source for generating answers from the LLM. This feature will also deploy a Bing v7 Search instance in Azure to retrieve web results from, however Bing v7 Search is not available in AzureUSGovernment regions, so this feature flag is **NOT** compatible with `AZURE_ENVIRONMENT AzureUSGovernment`. If you are using the `USE_WEB_CHAT`feature you can set the following values to enable safe search on the Bing v7 Search APIs.

- Run `azd env set USE_WEB_CHAT true` and `azd env set USE_BING_SAFE_SEARCH true`. Or use false to disable.

### Ungrounded Chat

This feature flag will enable the ability to interact directly with an LLM. This experience will be similar to the Azure AI Foundry Playground

- Run `azd env set USE_UNGROUNDED_CHAT true`. Or use false to disable.

## Azure Open AI resources

If you want to target an existing Azure Open AI instance...

```bash
azd env set EXISTING_AZURE_OPENAI_RESOURCE_GROUP {Name of resource group where existing AOAI instance is}
azd env set EXISTING_AZURE_OPENAI_SERVICE_NAME {Name of existing AOAI service}
azd env set EXISTING_AZURE_OPENAI_LOCATION {Location code of AOAI service}
```

If you want to use an existing model deployment or edit the defaults for deployment...

```bash
azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT {Name of GPT model deployment} # Use to provide the name of a deployment of the gpt-based model in the Azure Open AI service instance.
azd env set AZURE_OPENAI_CHATGPT_MODEL_NAME {The official GPT model name} # Use to select a different GPT model to be deployed to Azure OpenAI when the default (gpt-4o) isn't available to you.
azd env set AZURE_OPENAI_CHATGPT_MODEL_VERSION {The version of the GPT model} # Used to select a specific version of the GPT model above when the default (2024-05-13) isn't available to you.
azd env set AZURE_OPENAI_CHATGPT_SKU {The SKU of the GPT model} # Used to select a different GPT model SKU to be used on the deployment to Azure OpenAI when the default (Standard) isn't available.
azd env set AZURE_OPENAI_CHATGPT_MODEL_CAPACITY {The capacity for the GPT deployment} # Used to provide the provisioned capacity of the GPT model deployed to Azure OpenAI when you have reduced capacity.

azd env set AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME {Name of the embedding model deployment} # Use to provide the name of a deployment of the "text-embedding-ada-002" model in the Azure Open AI service instance in your subscription.
azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_NAME {The official embedding model name} # Used to select a different embeddings model to be deployed to Azure OpenAI when the default (text-embedding-ada-002) isn't available to you.
azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION {The version of the embedding model} # Use to select a specific version of the embeddings model above when the default (2) isn't available to you.
azd env set AZURE_OPENAI_EMBEDDINGS_SKU {The SKU of the embedding model} # Use to select a different embeddings model SKU to be used on the deployment to Azure OpenAI when the default (Standard) isn't available.
azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY {The capacity for the embedding deployment} # Use to provide the provisioned capacity of the embeddings model deployed to Azure OpenAI.
```

## Azure Search Service Settings

If you have regional restrictions or limited quota for Azure AI Search you can use the following variables to configure Azure Search...

```bash
azd env set SEARCH_SERVICE_SKU "{Sku for Azure Search Service}"` # Defaults to "standard3"
azd env set SEARCH_SERVICE_REPLICA_COUNT {number of replicas}` # Defaults to 3
```

## Custom Network Settings

### Custom Network CIDRs

If you want to specify custom CIDRs for the network deployment, use the following. More information on the network configuration of Info Assistant agent template can be found in our [Private virtual network and endpoint architecture](../architecture.md#private-virtual-network-and-endpoint-architecture)

- Run `azd env set USE_CUSTOM_NETWORK_SETTINGS true`. Then use the following variables to control the CIDR configurations.

``` bash
azd env set VNET_NETWORK_CIDR x.x.x.x/29
azd env set VNET_MONITOR_CIDR x.x.x.x/27 # requires at least a /27 range
azd env set VNET_STORAGE_ACCOUNT_CIDR x.x.x.x/28 # requires at least a /28 range
azd env set VNET_AI_CIDR x.x.x.x/29
azd env set VNET_WEBAPP_CIDR x.x.x.x/29
azd env set VNET_KEYVAULT_CIDR x.x.x.x/29
azd env set VNET_SEARCH_SERVICE_CIDR x.x.x.x/29
azd env set VNET_BING_SERVICE_CIDR x.x.x.x/29
azd env set VNET_OPENAI_CIDR x.x.x.x/29
azd env set VNET_INTEGRATION_CIDR x.x.x.x/26 # requires at least a /26 range
azd env set VNET_ACR_CIDR x.x.x.x/29
azd env set VNET_DNS_CIDR x.x.x.x/28 #requires at least a /28 range
```

### Network Security Perimeter (Preview)

[Network Security Perimeter (NSP)](https://learn.microsoft.com/en-us/azure/private-link/network-security-perimeter-concepts), helps Service Owners or Administrators to define logical network isolation boundaries and configure common public access controls for multiple PaaS resources for a consistent user experience and centralized enforcement.

By default, PaaS resources associated with a perimeter can only communicate with other PaaS resources associated with the same perimeter.

Within the perimeter, PaaS resources are assigned to a specific Network Profile (or profile for short). Each profile defines a set of Access Rules which can be used to selectively enable inbound or outbound communication between PaaS resources and endpoints external to the perimeter.

Info Assistant agent template has optional support to secure your Azure Key Vault by associating it to a NSP profile. The profile association is set into Learning mode which allows network administrators to understand the existing access patterns of their PaaS services before implementing enforcement of access rules.

To enable the Network Security Perimeter and associate the Azure Key Vault deployed by IA:

- Enable the preview feature on your Azure Subscription. Find more information on how to [Register preview features](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/preview-features?tabs=azure-cli#register-preview-feature) here.

```bash
# Use this command to check the status of the feature in your subscription.
az feature show --name AllowNSPInPublicPreview --namespace Microsoft.Network --output table

# Use this command to enable the Network Security Perimeter feature on your subscription. 
# Note: Registration can take several minutes to complete. Check status using the command 
# above for registration complete before attempting a deployment. 
az feature register --name AllowNSPInPublicPreview --namespace Microsoft.Network

```

- Once the feature is enabled, Run `azd env set USE_NETWORK_SECURITY_PERIMETER {boolean} # Defaults to false.`

## System Language Settings

Info Assistant agent template defaults to using English as the system language. You can use the following azd parameters to adjust the system language.

```bash
azd env set TARGET_TRANSLATION_LANGUAGE "{Language name in standard English}" # The language that Azure OpenAI will be prompted to generate the search terms in (i.e. "English", "Spanish", etc.)
azd env set SEARCH_INDEX_ANALYZER "{Search Index Analyzer code}" # The analyzer that the search index will used for all "searchable" fields. Supported analyzers can be found at https://learn.microsoft.com/en-us/azure/search/index-add-language-analyzers#language-analyzer-list
azd env set PROMPT_QUERYTERM_LANGUAGE "{Language Code}" # Supported Languages can be found at https://learn.microsoft.com/en-us/azure/ai-services/translator/language-support
```

## Custom Entra Objects

If you are unable to provision Azure Entra objects, you can manually configure them using our [App Registration Creation Guide](manual_app_registration.md). Then you can configure the following azd variables to use the manually created objects...

``` bash
  azd env set USE_CUSTOM_ENTRA_OBJECTS true
  azd env set AAD_WEB_CLIENT_ID "{web client id}"
  azd env set AAD_MGMT_CLIENT_ID "{mgmt client id}"
  azd env set AAD_MGMT_SP_ID "{mgmt service principal id}"
```

## Security and Expirations

The following settings manage the security related aspects of the Info Assistant agent template.

### Info Assistant Web App Security

- Run `azd env set REQUIRE_WEBSITE_SECURITY_MEMBERSHIP {boolean}` to determine whether a user needs to be granted explicit access to the website via an Azure AD Enterprise Application membership (true) or allow the website to be available to anyone in the Azure tenant (false). Defaults to false. If set to true, A tenant level administrator will be required to grant the implicit grant workflow for the Azure AD App Registration manually.
- Run `azd env set SECRET_EXPIRATION_DAYS {number of days before kv secret expires}` Defaults to 730. This value determines the number of days before a secret in the key vault are expired. We have NOT included automatic secret rotation in this deployment. See <https://learn.microsoft.com/en-us/azure/key-vault/keys/how-to-configure-key-rotation> for more information on enabling cryptographic key auto-rotation.
- Run `azd env set ENTRA_OWNERS "{comma separated list of Entra Ids}"` Defaults to "". Additional user id's you wish to assign to the Owner role of created Azure Entra App Registrations. The values need to be the primary identity (<username@mydomain.com>) or a user to be assigned the Owner role.
- Run `azd env set SERVICE_MANAGEMENT_REFERENCE "{Service Management Reference ID (GUID)}"` Defaults to "". Sets the service management reference value on Azure Entra objects created by Information Assistant if required by your organization.
PASSWORD_LIFETIME | No | Defaults to 365. The number of days that passwords associated with created identities are set to expire after creation. Change this setting if needed to conform to you policy requirements

## DDOS Protection Plan

It is recommended to use IA with a DDoS Protection Plan for Virtual Network Protection, but it is not required. There is a limit of 1 DDoS protection plan for a subscription in a region. You can reuse an existing DDoS plan in your tenant, Information Assistant can deploy one for you, or you can choose to not use a DDoS Protection Plan on your virtual network. Use the following variables to configure for your environment...

- Run `azd env set USE_DDOS_PROTECTION_PLAN {boolean}` Defaults to false. This setting will determine if the private vnet that is deployed is associated to a DDoS protection plan or not. When true, this setting can be used in conjunction with `DDOS_PLAN_ID` to specify a specific DDOS protection plan ID or if omitted the scripts will prompt during deployment to select an available DDOS protection plan.
- Run `azd env set DDOS_PLAN_ID "/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/ddosProtectionPlans/{ddos plan name}"` If USE_DDOS_PROTECTION_PLAN is set to `true`, you can specify an existing DDoS Plan ID. If no value is provided, the deployment scripts will prompt you with a choice to use the first found existing DDoS plan in your subscription or Information Assistant will create one automatically. To use an existing DDoS plan, update the subscription id, resource group name and DDoS plan name values. See [using DDoS protection plans for more details](/docs/deployment/using_ddos_protection_plan.md).

## Data Collection

The CUA GUID which is pre-configured will tell Microsoft about the usage of this software. Please see [Data Collection Notice](/README.md#data-collection-notice) for more information. <br/><br/>You may provide your own CUA GUID by changing the value in **CUSTOMER_USAGE_ATTRIBUTION_ID**. Ensure you understand how to properly notify your customers by reading <https://learn.microsoft.com/partner-center/marketplace/azure-partner-customer-usage-attribution#notify-your-customers>.<br/><br/>To disable data collection, set **USE_CUSTOMER_USAGE_ATTRIBUTION** to `false`.

```bash
azd env set USE_CUSTOMER_USAGE_ATTRIBUTION {boolean} # Defaults to true
azd env set CUSTOMER_USAGE_ATTRIBUTION_ID {CUA GUID} 
```

## Store Terraform State in Azure

By default terraform will store it's state file locally in the `/.azure/{environment name}/infra` folder in the workspace. If you are using a GitHub Codespace and it expires, you will lose any local state files stored in the Codespace. To avoid this scenario, you can choose to store the Terraform state files in an Azure Storage Account of your choosing (not the one created by Information Assistant).

To enable the deployment to store Terraform state files in an Azure Storage Account instead of the local file system...

```bash
azd env set STORE_TF_STATE_IN_AZURE true
azd env set TF_BACKEND_RESOURCE_GROUP {resource group name} # A resource group in the same subscription where you plan to deploy Information Assistant to that has an existing Azure storage account to store the Terraform state into
azd env set TF_BACKEND_STORAGE_ACCOUNT {storage acccount name} # The storage account name that already exists in the resource group provided in TF_BACKEND_RESOURCE_GROUP
azd env set TF_BACKEND_CONTAINER {container name in the storage account} # The name of a container that already exists in the stoage account provided in TF_BACKEND_STORAGE_ACCOUNT
```

## Miscellaneous

- Run `azd env set APPLICATION_TITLE "{Custom Application Title}"` Defaults to "". Providing a value for this parameter will replace the Information Assistant's title in the black banner at the top of the UX.

- Run `azd env set CHAT_WARNING_BANNER_TEXT "{Banner text}"` Defaults to "". Provide a value in this parameter to display a header and footer to the UX of Information Assistant with the included warning banner text.
