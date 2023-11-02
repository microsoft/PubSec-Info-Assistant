# IA Accelerator Features

Please see below sections for coverage of IA Accelerator features. 

## Retrieval Augmented Generation (RAG)

**Retrieve Contextually Relevant Documents:** Utilize Azure Cognitive Search's indexing capabilities to retrieve documents that are contextually relevant for precise answers.

**Dynamic Model Selection:** Use GPT models (GPT-3.5 or GPT-4) tailored to your needs.

Technical overview of RAG: [Retrieval Augmented Generation using Azure Machine Learning prompt flow](https://learn.microsoft.com/en-us/azure/machine-learning/concept-retrieval-augmented-generation?view=azureml-api-2#why-use-rag)

## Prompt Engineering

**Adaptable Prompt Structure:** Our prompt structure is designed to be compatible with current and future Azure OpenAI's Chat Completion API versions and GPT models, ensuring flexibility and sustainability.

**Dynamic Prompts:** Dynamic prompt context based on the selected GPT model and users settings.

**Built-in Chain of Thought (COT):** COT is integrated into our prompts to address fabrications that may arise with large language models (LLM). COT encourages the LLM to follow a set of instructions, explain its reasoning, and enhances the reliability of responses.

**Few-Shot Prompting:** We employ few-shot prompting in conjunction with COT to further mitigate fabrications and improve response accuracy.

Go here for more information on [Prompt engineering techniques](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/advanced-prompt-engineering?pivots=programming-language-chat-completions)

## Document Pre-Processing

**Custom Document Chunking:** The Azure OpenAI GPT models have a maximum token limit, which includes both input and output tokens. Tokens are units of text which can represent a single word, a part of a word, or even a character, depending on the specific language and text encoding being used. Consequently the model will not be able to process a 500 page text based document. Likewise, the models will not be able to process complex file types, such as PDF. This is why we pre-process these documents, before passing these to our search capability to then be exposed by the RAG pattern. Our process focused on

* content extraction from text-based documents
* creating a standard JSON representation of all a documents text-based content
* chunking and saving metadata into manageable sized to be used in the RAG pattern

The Information Assistant Accelerator [pre-processes](/docs/features/document_pre_processing.md) certain document types to allow better understanding of large complex documents. 

We also log the status of the pre-processing in Azure Cosmos DB. View our [Status Logging](/functions/shared_code/status_log.md) page for more details.

Additionally, there are many configuration values that can be altered to effect the performance and behaviors of the chunking patterns. More details on the deployment configurations can be found in our [Function Flow documentation](/docs/functions_flow.md)

## Image Search
**Text-Based Image Retrieval** , With this addition, you can easily search for images in the Retrieval Augmented Generation (RAG) application.

#### How It Works

When you upload images, data processing pipeline extractions captions and metadata of images and stores them in Azure Cognitive Search Index. Now, when users ask questions using text, Retrieval pipeline extracts image captions matching user queries, allowing user to find images quickly. Just click on the citation, and the image will appear, making content retrieval a streaight forward process. Additional information on this can be found [here](/docs/features/document_pre_processing.md)

#### What's Coming

We're starting with text-based image retrieval, but in the future, we have plans to extend this functionality to include image-to-image search, offering even more robust options for our users.


## Azure Cognitive Search Integration

This accelerator employs Vector Hybrid Search which combines vector similarity with keyword matching to enhance search accuracy. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

To learn more, please visit the [Cognitive Search](/docs/features/cognitive_search.md) feature page.

## Customization and Personalization

**User-Selectable Options:** Users can fine-tune their interactions by adjusting settings such as temperature and persona, tailoring the AI experience to their specific needs.

**UX Settings:** Easily tweak behavior and experiment with various options directly in the user interface.

## Enhanced AI Interaction

**Simple File Upload and Status:** We have put uploading of files into the Accelerator in the hands of the users by providing a simple drag-and-drop user interface for adding new content and a status page for monitoring document pre-processing.

**Visualizing Thought Process:** Gain insights into the AI's decision-making process by visualizing how it arrives at answers, providing transparency and control.

**Proper Citations and References:** The platform generates referenceable source content, designed to enhance trustworthiness and accountability in AI-generated responses.

**Image Captioning**: The platform can generate captions for images, providing additional context for the user. **NOTE**:"CAPTION" and "DENSE_CAPTIONS" are only supported in Azure GPU regions (East US, France Central, Korea Central, North Europe, Southeast Asia, West Europe, West US)

## User Experience

![Chat screen](/docs/images/info_assistant_chatscreen.png)

The end user leverages the web interface as the primary method to engage with the IA Accelerator, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined on the [User Experience](/docs/features/user_experience.md) page. 

## Developer Settings

### Configuring your own language ENV file

At deployment time, you can alter the behavior of the IA Accelerator to use a language of your choosing across it's Azure Cognitive Search and Azure OpenAI prompting. See [Configuring your own language ENV file](/docs/features/configuring_language_env_files.md) more information.

### Debugging functions

Check out how to [Debug the Azure functions locally in VSCode](/docs/function_debug.md)

### Debugging the web app

Check out how to [Debug the Information Assistant Web App](/docs/webapp_debug.md)

### Debugging the container web app

Check out how to [Debug the Information Assistant Web App](/docs/container_webapp_debug.md)


### Build pipeline for Sandbox

Setting up a pipeline to deploy a new Sandbox environment requires some manual configuration. Review the details of the [Procedure to setup sandbox environment](/docs/deployment/setting_up_sandbox_environment.md) here.

### Customer Usage Attribution

A feature offered within Azure, "Customer Usage Attribution" associates usage from Azure resources in customer subscriptions created while deploying your IP with you as a partner. Forming these associations in internal Microsoft systems brings greater visibility to the Azure footprint running the Information Assistant Accelerator.

Check out how to [enable Customer Usage Attribution](/docs/features/enable_customer_usage_attribution.md)

## Sovereign Region Deployment

Check out how to [setup Sovereign Region Deployment](/docs/deployment/enable_sovereign_deployment.md)

## Works in Progress (Future releases)

**Adding Evaluation Guidance and Metrics:** To ensure transparency and accountability, we are researching comprehensive evaluation guidance and metrics. This will assist users in assessing the performance and trustworthiness of AI-generated responses, fostering confidence in the platform.