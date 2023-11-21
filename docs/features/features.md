# IA Accelerator Features

Please see below sections for coverage of IA Accelerator features.

* [Retrieval Augmented Generation (RAG)](/docs/features/features.md#retrieval-augmented-generation-rag)
* [Prompt Engineering](/docs/features/features.md#prompt-engineering)
* [Document Pre-Processing](/docs/features/features.md#document-pre-processing)
* [Image Search](/docs/features/features.md#image-search)
* [Azure Cognitive Search Integration](/docs/features/features.md#azure-cognitive-search-integration)
* [Customization and Personalization](/docs/features/features.md#customization-and-personalization)
* [Enhanced AI Interaction](/docs/features/features.md#enhanced-ai-interaction)
* [User Experience](/docs/features/features.md#user-experience)
* [Works in Progress](/docs/features/features.md#works-in-progress-future-releases)

## Retrieval Augmented Generation (RAG)

**Retrieve Contextually Relevant Documents:** Utilize Azure Cognitive Search's Vector Hybrid Search capabilities to retrieve documents that are contextually relevant for precise answers. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

**Dynamic Model Selection:** Use GPT models (GPT-3.5 or GPT-4) tailored to your needs.

Technical overview of RAG: [Retrieval Augmented Generation using Azure Machine Learning prompt flow](https://learn.microsoft.com/en-us/azure/machine-learning/concept-retrieval-augmented-generation?view=azureml-api-2#why-use-rag)

## Prompt Engineering

**Adaptable Prompt Structure:** Our prompt structure is designed to be compatible with current and future Azure OpenAI's Chat Completion API versions and GPT models, ensuring flexibility and sustainability.

**Dynamic Prompts:** Dynamic prompt context based on the selected GPT model and users settings.

**Built-in Chain of Thought (COT):** COT is integrated into our prompts to address fabrications that may arise with Large Language Models (LLM). COT encourages the LLM to follow a set of instructions, explain its reasoning, and enhances the reliability of responses.

**Few-Shot Prompting:** We employ few-shot prompting in conjunction with COT to further mitigate fabrications and improve response accuracy.

Go here for more information on [Prompt engineering techniques](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/advanced-prompt-engineering?pivots=programming-language-chat-completions)

## Document Pre-Processing

### Supported Document Types

Information Assistant supports the following document types:

Pipeline | File Types
--- | ---
Text-based | pdf, docx, html, htm, csv, md, pptx, txt, json, xlsx, xml, eml, msg
Images | jpg, jpeg, png, gif, bmp, tif, tiff

**Custom Document Chunking:** The Azure OpenAI GPT models have a maximum token limit, which includes both input and output tokens. Tokens are units of text which can represent a single word, a part of a word, or even a character, depending on the specific language and text encoding being used. Consequently the model will not be able to process a 500 page text based document. Likewise, the models will not be able to process complex file types, such as PDF. This is why we pre-process these documents, before passing these to our search capability to then be exposed by the RAG pattern. Our process focused on

* content extraction from text-based documents
  * [Azure AI Document Intelligence](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview?view=doc-intel-3.1.0) for PDFs
  * [Unstructure.io](https://unstructured.io/) for all other text-based types
* creating a standard JSON representation of all a documents text-based content
* chunking and saving metadata into manageable sizes to be used in the RAG pattern

The Information Assistant Accelerator [pre-processes](/docs/features/document_pre_processing.md) certain document types to allow better understanding of large complex documents.

We also log the status of the pre-processing in Azure Cosmos DB. View our [Status Logging](/functions/shared_code/status_log.md) page for more details.

Additionally, there are many configuration values that can be altered to effect the performance and behaviors of the chunking patterns. More details on the deployment configurations can be found in our [Function Flow documentation](/docs/functions_flow.md)

## Image Search

### Text-Based Image Retrieval

With this addition, you can easily search for images in the Retrieval Augmented Generation (RAG) application.

#### How It Works

When you upload images, data processing pipeline extractions captions and metadata of images and stores them in Azure Cognitive Search Index. Now, when users ask questions using text, Retrieval pipeline extracts image captions matching user queries, allowing user to find images quickly. Just click on the citation, and the image will appear, making content retrieval a straight forward process. Additional information on this can be found [here](/docs/features/document_pre_processing.md)

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

## Works in Progress (Future releases)

### Image Similarity Search

We've starting with text-based image retrieval, but in the future, we have plans to extend this functionality to include image-to-image search, offering even more robust options for our users.

### Adding Evaluation Guidance and Metrics

To ensure transparency and accountability, we are researching comprehensive evaluation guidance and metrics. This will assist users in assessing the performance and trustworthiness of AI-generated responses, fostering confidence in the platform.
