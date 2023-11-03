# Information Assistant Accelerator

This industry accelerator showcases integration between Azure and OpenAI's large language models. It leverages Azure Cognitive Search for data retrieval and ChatGPT-style Q&A interactions. Using the Retrieval Augmented Generation (RAG) design pattern with Azure Open AI's GPT models, it provides a natural language interaction to discover relevant responses to user queries. Azure Cognitive Search simplifies data ingestion, transformation, indexing, and multilingual translation.

The accelerator adapts prompts based on the model type for enhanced performance. Users can customize settings like temperature and persona for personalized AI interactions. It offers features like explainable thought processes, referenceable citations, and direct content for verification.

---

![Process Flow](/docs/process_flow.drawio.png)

## Features

The IA Accelerator contains several features, many of which have their own documentation.

* [Retrieval Augmented Generation (RAG)](/docs/features/features.md#retrieval-augmented-generation-rag)
* [Prompt Engineering](/docs/features/features.md#prompt-engineering)
* [Document Pre-Processing](/docs/features/features.md#document-pre-processing)
* [Image Search](/docs/features/features.md#image-search)
* [Azure Cognitive Search Integration](/docs/features/features.md#azure-cognitive-search-integration)
* [Customization and Personalization](/docs/features/features.md#customization-and-personalization)
* [Enhanced AI Interaction](/docs/features/features.md#enhanced-ai-interaction)
* [User Experience](/docs/features/features.md#user-experience)
* [Developer Settings](/docs/features/features.md#developer-settings)
  * [Configuring your own language ENV file](/docs/features/features.md#configuring-your-own-language-env-file)
  * [Debugging functions](/docs/features/features.md#debugging-functions)
  * [Debugging the web app](/docs/features/features.md#debugging-the-web-app)
  * [Debugging the container web app](/docs/features/features.md#debugging-the-container-web-app)
  * [Build pipeline for Sandbox](/docs/features/features.md#build-pipeline-for-sandbox)
  * [Customer Usage Attribution](/docs/features/features.md#customer-usage-attribution)
* [Sovereign Region Deployment](/docs/features/features.md#sovereign-region-deployment)
* [Works in Progress](/docs/features/features.md#works-in-progress-future-releases)

For a detailed review see our [Features](/docs/features/features.md) page.

## Data Collection Notice

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

### About Data Collection

Data collection by the software in this repository is used by Microsoft solely to help justify the efforts of the teams who build and maintain this accelerator for our customers. It is your choice to leave this enabled, or to disable data collection.

Data collection is implemented by the presence of a tracking GUID in the environment variables at deployment time. The GUID is associated with each Azure resource deployed by the installation scripts. This GUID is used by Microsoft to track the Azure consumption this open source solution generates.

### How to Disable Data Collection

To disable data collection, follow the instructions in the [Configure ENV files](/docs/deployment/deployment.md#configure-env-files) section for `ENABLE_CUSTOMER_USAGE_ATTRIBUTION` variable before deploying.

## Responsible AI

The Information Assistant (IA) Accelerator and Microsoft are committed to the advancement of AI driven by ethical principles that put people first.

**Read our [Transparency Note](/docs/transparency.md)**

Find out more with Microsoft's [Responsible AI resources](https://www.microsoft.com/en-us/ai/responsible-ai)

## Deployment

Please follow the instructions in [the deployment guide](/docs/deployment/deployment.md) to install the IA Accelerator in your Azure subscription.

Once completed, follow the [instructions for using IA Accelerator for the first time](/docs/deployment/using_ia_first_time.md).

## Navigating the Source Code

This project has the following structure:

File/Folder | Description
---|---
.devcontainer/ | Dockerfile, devcontainer configuration, and supporting script to enable both CodeSpaces and local DevContainers.
app/backend/ | The middleware part of the IA website that contains the prompt engineering and provides an API layer for the client code to pass through when communicating with the various Azure services. This code is python based and hosted as a Flask app.
app/enrichment/ | The text-based file enrichment process that handles language translation, embedding the text chunks, and inserting text chunks into the Azure Cognitive Search hybrid index. This code is python based and is hosted as a Flask app that subscribes to an Azure Storage Queue.
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

## Resources

* [Revolutionize your Enterprise Data with ChatGPT: Next-gen Apps w/ Azure OpenAI and Cognitive Search](https://aka.ms/entgptsearchblog)
* [Azure Cognitive Search](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
* [Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/overview)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft’s Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Reporting Security Issues

For security concerns, please see [Security Guidelines](./SECURITY.md)
