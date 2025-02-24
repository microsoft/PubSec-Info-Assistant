# Information Assistant (IA) agent template features

Please see below sections for coverage of IA agent template features.

* [Retrieval Augmented Generation (RAG)](/docs/features/features.md#retrieval-augmented-generation-rag)
* [Prompt Engineering](/docs/features/features.md#prompt-engineering)
* [Document Pre-Processing](/docs/features/features.md#document-pre-processing)
* [Bing Search And Compare](/docs/features/features.md#bing-search-and-compare)
* [Image Search](/docs/features/features.md#image-search)
* [Azure AI Search Integration](/docs/features/features.md#azure-ai-search-integration)
* [Customization and Personalization](/docs/features/features.md#customization-and-personalization)
* [Enhanced AI Interaction](/docs/features/features.md#enhanced-ai-interaction)
* [User Experience](/docs/features/features.md#user-experience)
* [Document Deletion](/docs/features/features.md#document-deletion)
* [Works in Progress](/docs/features/features.md#works-in-progress-future-releases)

## Retrieval Augmented Generation (RAG)

**Retrieve Contextually Relevant Documents:** Utilize Azure AI Search's Vector Hybrid Search capabilities to retrieve documents that are contextually relevant for precise answers. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

**Dynamic Model Selection:** Use GPT models (GPT-3.5 or GPT-4) tailored to your needs.

Technical overview of RAG: [Retrieval Augmented Generation using Azure Machine Learning prompt flow](https://learn.microsoft.com/azure/machine-learning/concept-retrieval-augmented-generation?view=azureml-api-2#why-use-rag)

## Prompt Engineering

**Adaptable Prompt Structure:** Our prompt structure is designed to be compatible with current and future Azure OpenAI's Chat Completion API versions and GPT models, ensuring flexibility and sustainability.

**Dynamic Prompts:** Dynamic prompt context based on the selected GPT model and users settings.

**Built-in Chain of Thought (COT):** COT is integrated into our prompts to address fabrications that may arise with Large Language Models (LLM). COT encourages the LLM to follow a set of instructions, explain its reasoning, and enhances the reliability of responses.

**Few-Shot Prompting:** We employ few-shot prompting in conjunction with COT to further mitigate fabrications and improve response accuracy.

Go here for more information on [Prompt engineering techniques](https://learn.microsoft.com/azure/ai-services/openai/concepts/advanced-prompt-engineering?pivots=programming-language-chat-completions)

## Document Pre-Processing

The Information Assistant agent template connects to the Azure Storage Account "upload" container using an Azure AI Search [Datasource for Azure Blob Storage](https://learn.microsoft.com/en-us/AZURE/search/search-howto-indexing-azure-blob-storage). This data source is configured to detect when blobs are added, updated, or deleted to trigger the document pre-processing steps below.

### Supported Document Types

Information Assistant uses the Azure AI Search [Document Extraction cognitive skill](https://learn.microsoft.com/en-us/azure/search/cognitive-search-skill-document-extraction) by default.

[Supported document types](https://learn.microsoft.com/en-us/azure/search/cognitive-search-skill-document-extraction) for the Document Extraction cognitive skill can be found on MSLearn.

### Secure Architecture

The Information Assistant deploys it's Azure Services with public network access disabled and to use private endpoints on a trusted Azure Virtual Network. To enable Azure AI Search to communicate with Azure Storage, Azure AI Services, and Azure Open AI Service the Azure AI Search configuration will use [shared private links](https://learn.microsoft.com/en-us/azure/search/search-indexer-howto-access-private?tabs=cli-create) to connect with these other Azure services. Details of this configuration can be found in our Azure AI Search Terraform module at `infra/core/search/search-services.tf`.

## Bing Search And Compare

"Bing Search" and "Bing Compare." The former enables users to seamlessly perform Bing searches, with the retrieved results processed by the LLM and enriched with URL citations for more informative responses.
The latter, "Bing Compare," takes a grounded LLM response and performs a second Bing search, integrating citations from both sources for a comprehensive answer.

Additionally, a "Switch to Web" button in the subtitle bar allows users to transition between "Work" and "Web" workspaces, directing prompts either to the grounded LLM with access to Bing-related functionalities or behaving as if the "Search Bing" button was pressed.
 In the "Web" workspace, a "Compare Data" button facilitates the comparison of Bing search results with grounded LLM responses.
 These features empower users to seamlessly access and validate information across various sources within the chat interface.
 More information can be found in the [markdown here](/docs/features/bing_search.md)

## Image Search

### Text-Based Image Retrieval

With this addition, you can easily search for images in the Retrieval Augmented Generation (RAG) application.

#### How It Works

When you upload images, data processing pipeline extractions captions and metadata of images and stores them in Azure AI Search Index. Now, when users ask questions using text, Retrieval pipeline extracts image captions matching user queries, allowing user to find images quickly. Just click on the citation, and the image will appear, making content retrieval a straight forward process. Additional information on this can be found [here](/docs/features/document_pre_processing.md)

Image Search is only available in regions that support dense captions. For a full list of these regions please see the official documentation for Azure Vision Image Captions [here](https://learn.microsoft.com/azure/ai-services/computer-vision/concept-describe-images-40?tabs=dense)

## Azure AI Search Integration

This agent template employs Vector Hybrid Search which combines vector similarity with keyword matching to enhance search accuracy. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

To learn more, please visit the [Cognitive Search](/docs/features/cognitive_search.md) feature page.

## Customization and Personalization

**User-Selectable Options:** Users can fine-tune their interactions by adjusting settings such as temperature and persona, tailoring the AI experience to their specific needs.

**UX Settings:** Easily tweak behavior and experiment with various options directly in the user interface.

## Enhanced AI Interaction

**Simple File Upload and Status:** We have put uploading of files into the agent template in the hands of the users by providing a simple drag-and-drop user interface for adding new content and a status page for monitoring document pre-processing.

**Visualizing Thought Process:** Gain insights into the AI's decision-making process by visualizing how it arrives at answers, providing transparency and control.

**Proper Citations and References:** The platform generates referenceable source content, designed to enhance trustworthiness and accountability in AI-generated responses.

**Image Captioning**: The platform can generate captions for images, providing additional context for the user. **NOTE**:"CAPTION" and "DENSE_CAPTIONS" are only supported in Azure GPU regions (East US, France Central, Korea Central, North Europe, Southeast Asia, West Europe, West US)

## User Experience

![Chat screen](/docs/images/info-assist-chat-ui.png)

The end user leverages the web interface as the primary method to engage with the IA agent template, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined on the [User Experience](/docs/features/user_experience.md) page.

## Document Deletion

There are multiple options for deleting documents in the IA agent template. Most users will perform document deletion in the UI, while experienced technical users may opt for deleting files through the underlying infrastructure. Document deletions are not instantaneous and can take up to ten minutes to propagate through all components of the system.

### File Deletion in the UI

Users can delete documents through the same Manage Content UI they use to review the status of files they have uploaded. They can use filters to locate documents, view detailed status and history of the document, then optionally delete the document. Additional information on document management, including how to upload, search, filter content and delete documents is available on the [User Experience](/docs/features/user_experience.md) page.

### Technical File Deletion from the upload container

An experienced technical user can delete a document from the upload container in the `infoasststore*****` Storage Account. The Azure AI Search Indexer runs on an interval timer and will delete the relevant documents from the AI Search Index. It will then update the state of the document, which can be viewed in the Upload Status portion of the UI under the Manage Content tab at the top right.

## Works in Progress (Future releases)

### Image Similarity Search

We've starting with text-based image retrieval, but in the future, we have plans to extend this functionality to include image-to-image search, offering even more robust options for our users.

### Adding Evaluation Guidance and Metrics

To ensure transparency and accountability, we are researching comprehensive evaluation guidance and metrics. This will assist users in assessing the performance and trustworthiness of AI-generated responses, fostering confidence in the platform.
