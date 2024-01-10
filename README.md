# Information Assistant Accelerator

> [!IMPORTANT]  
> As of November 15, 2023, Azure Cognitive Search has been renamed to Azure AI Search. Azure Cognitive Services have also been renamed to Azure AI Services.

## Table of Contents

- [Features](#features)
- [Azure account requirements](#azure-account-requirements)
- [Azure Deployment](./docs/deployment/deployment.md)
  - [Codespaces Setup](./docs/deployment/deployment.md#development-environment-configuration)
  - [Cost Estimation](./docs/deployment/deployment.md#sizing-estimator)
  - [Configuring ENV parameters](./docs/deployment/deployment.md#configure-env-files)
  - [Authenticating to Azure](./docs/deployment/deployment.md#log-into-azure-using-the-azure-cli)
  - [Deploying to Azure](./docs/deployment/deployment.md#deploy-and-configure-azure-resources)
  - [Troubleshooting Deployment & Startup Issues](./docs/deployment/worbook_usage.md)
  - [Considerations for Production Adoption](./docs/deployment/considerations_production.md)
- [Enabling optional features](./docs/features/optional_features.md)
- [Using the app](/docs/deployment/using_ia_first_time.md)
- [Responsible AI](#responsible-ai)
  - [Transparency Note](#transparency-note)
- [Data Collection Notice](#data-collection-notice)
- [Resources](#resources)
  - [Known Issues](./docs/knownissues.md)
  - [Functional Tests](./tests/README.md)
  - [Navigating the source code](#navigating-the-source-code)
  - [Architectural Decisions](/docs/features/architectural_decisions.md)
  - [References](#references)
  - [Trademarks](#trademarks)
  - [Code of Conduct](#code-of-conduct)
  - [Reporting security issues](#reporting-security-issues)


[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=601652366&machine=basicLinux32gb&devcontainer_path=.devcontainer%2Fdevcontainer.json&location=eastus)

This industry accelerator showcases integration between Azure and OpenAI's large language models. It leverages Azure AI Search for data retrieval and ChatGPT-style Q&A interactions. Using the Retrieval Augmented Generation (RAG) design pattern with Azure Open AI's GPT models, it provides a natural language interaction to discover relevant responses to user queries. Azure AI Search simplifies data ingestion, transformation, indexing, and multilingual translation.

The accelerator adapts prompts based on the model type for enhanced performance. Users can customize settings like temperature and persona for personalized AI interactions. It offers features like explainable thought processes, referenceable citations, and direct content for verification.

## Features

The IA Accelerator contains several features, many of which have their own documentation.

- Examples of custom Retrieval Augmented Generation (RAG), Prompt Engineering, and Document Pre-Processing
- Azure AI Search Integration to include text search of both text documents and images
- Customization and Personalization to enable enhanced AI interaction

For a detailed review see our [Features](./docs/features/features.md) page.

![Process Flow](/docs/process_flow.drawio.png)

## Azure account requirements

**IMPORTANT:** In order to deploy and run this example, you'll need:

* **Azure account**. If you're new to Azure, [get an Azure account for free](https://azure.microsoft.com/free/cognitive-search/) and you'll get some free Azure credits to get started.
* **Azure subscription with access enabled for the Azure OpenAI service**. You can request access with [this form](https://aka.ms/oaiapply).
  * **Access to one of the following Azure OpenAI models**:

    Model Name | Supported Versions
    ---|---
    gpt-35-turbo | 0301, 0613
    **gpt-35-turbo-16k** | current version
    **gpt-4** | current version
    gpt-4-32k | current version

    **Important:** Gpt-35-turbo-16k (0613) is recommended. GPT 4 models may achieve better results from the IA Accelerator.
  * (Optional) **Access to the following Azure OpenAI model for embeddings**. Some open source embedding models may perform better for your specific data or use case. For the use case and data Information Assistant was tested for we recommend using the following Azure OpenAI embedding model.

    Model Name | Supported Versions
    ---|---
    **text-embedding-ada-002** | current version
* **Azure account permissions**:
  * Your Azure account must have `Microsoft.Authorization/roleAssignments/write` permissions, such as [Role Based Access Control Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#role-based-access-control-administrator-preview), [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator), or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner) on the subscription.
  * Your Azure account also needs `Microsoft.Resources/deployments/write` permissions on the subscription level.
  * Your Azure account also needs `microsoft.directory/applications/create` and `microsoft.directory/servicePrincipals/create`, such as [Application Administrator](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#application-administrator) Entra built-in role.
* **To have accepted the Azure AI Services Responsible AI Notice** for your subscription. If you have not manually accepted this notice please follow our guide at [Accepting Azure AI Service Responsible AI Notice](./docs/deployment/accepting_responsible_ai_notice.md).
* (Optional) Have [Visual Studio Code](https://code.visualstudio.com/) installed on your development machine. If your Azure tenant and subscription have conditional access policies or device policies required, you may need to open your Codespace in VS Code to satisfy the required polices.

## Deployment

Please follow the instructions in [the deployment guide](/docs/deployment/deployment.md) to install the IA Accelerator in your Azure subscription.

Once completed, follow the [instructions for using IA Accelerator for the first time](/docs/deployment/using_ia_first_time.md).

## Responsible AI

The Information Assistant (IA) Accelerator and Microsoft are committed to the advancement of AI driven by ethical principles that put people first.

### Transparency Note

**Read our [Transparency Note](/docs/transparency.md)**

Find out more with Microsoft's [Responsible AI resources](https://www.microsoft.com/en-us/ai/responsible-ai)

## Data Collection Notice

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

### About Data Collection

Data collection by the software in this repository is used by Microsoft solely to help justify the efforts of the teams who build and maintain this accelerator for our customers. It is your choice to leave this enabled, or to disable data collection.

Data collection is implemented by the presence of a tracking GUID in the environment variables at deployment time. The GUID is associated with each Azure resource deployed by the installation scripts. This GUID is used by Microsoft to track the Azure consumption this open source solution generates.

### How to Disable Data Collection

To disable data collection, follow the instructions in the [Configure ENV files](/docs/deployment/deployment.md#configure-env-files) section for `ENABLE_CUSTOMER_USAGE_ATTRIBUTION` variable before deploying.

## Resources

### Navigating the Source Code

This project has the following structure:

File/Folder | Description
---|---
.devcontainer/ | Dockerfile, devcontainer configuration, and supporting script to enable both Codespaces and local DevContainers.
app/backend/ | The middleware part of the IA website that contains the prompt engineering and provides an API layer for the client code to pass through when communicating with the various Azure services. This code is python based and hosted as a Flask app.
app/enrichment/ | The text-based file enrichment process that handles language translation, embedding the text chunks, and inserting text chunks into the Azure AI Search hybrid index. This code is python based and is hosted as a Flask app that subscribes to an Azure Storage Queue.
app/frontend/ | The User Experience layer of the IA website. This code is Typescript based and hosted as a Vite app and compiled using npm.
azure_search/ | The configuration of the Azure Search hybrid index that is applied in the deployment scripts.
docs/adoption_workshop/ | PPT files that match what is covered in the Adoption Workshop videos in Discussions.
docs/deployment/ | Detailed documentation on how to deploy and start using Information Assistant.
docs/features/ | Detailed documentation of specific features and development level configuration for Information Assistant.
docs/ | Other supporting documentation that is primarily linked to from the other markdown files.
functions/ | The pipeline of Azure Functions that handle the document extraction and chunking as well as the custom CosmosDB logging.
infra/ | The BICEP scripts that deploy the entire IA Accelerator. The overall accelerator is orchestrated via the `main.bicep` file but most of the resource deployments are modularized under the **core** folder.
pipelines/ | Azure DevOps pipelines that can be used to enable CI/CD deployments of the accelerator.
scripts/environments/ | Deployment configuration files. This is where all external configuration values will be set.
scripts/ | Supporting scripts that perform the various deployment tasks such as infrastructure deployment, Azure WebApp and Function deployments, building of the webapp and functions source code, etc. These scripts align to the available commands in the `Makefile`.
tests/ | Functional Test scripts that are used to validate a deployed Information Assistant's document processing pipelines are working as expected.
Makefile | Deployment command definitions and configurations. You can use `make help` to get more details on available commands.
README.md | Starting point for this repo. It covers overviews of the Accelerator, Responsible AI, Environment, Deployment, and Usage of the Accelerator.

### References

- [Revolutionize your Enterprise Data with ChatGPT: Next-gen Apps w/ Azure OpenAI and Cognitive Search](https://aka.ms/entgptsearchblog)
- [Azure AI Search](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/overview)

### Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft’s Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.

### Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### Reporting Security Issues

For security concerns, please see [Security Guidelines](./SECURITY.md)
