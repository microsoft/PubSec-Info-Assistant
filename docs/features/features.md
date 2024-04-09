# IA Accelerator Features

Please see below sections for coverage of IA Accelerator features.

* [Retrieval Augmented Generation (RAG)](/docs/features/features.md#retrieval-augmented-generation-rag)
* [Prompt Engineering](/docs/features/features.md#prompt-engineering)
* [Document Pre-Processing](/docs/features/features.md#document-pre-processing)
* [Bing Search And Compare](/docs/features/features.md#bing-search-and-compare)
* [Image Search](/docs/features/features.md#image-search)
* [Azure AI Search Integration](/docs/features/features.md#azure-ai-search-integration)
* [Assistants (Preview)](/docs/features/features.md#autonomous-reasoning-with-assistants-agents)
* [Customization and Personalization](/docs/features/features.md#customization-and-personalization)
* [Enhanced AI Interaction](/docs/features/features.md#enhanced-ai-interaction)
* [User Experience](/docs/features/features.md#user-experience)
* [Document Deletion](/docs/features/features.md#document-deletion)
* [Works in Progress](/docs/features/features.md#works-in-progress-future-releases)

## Retrieval Augmented Generation (RAG)

**Retrieve Contextually Relevant Documents:** Utilize Azure AI Search's Vector Hybrid Search capabilities to retrieve documents that are contextually relevant for precise answers. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

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

## Azure AI Search Integration

This accelerator employs Vector Hybrid Search which combines vector similarity with keyword matching to enhance search accuracy. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

To learn more, please visit the [Cognitive Search](/docs/features/cognitive_search.md) feature page.

## Autonomous Reasoning with Assistants (Agents)

We are rolling out the Math Assistant and Tabular Data Assistant in a preview mode. The Math Assistant combines natural language understanding with robust mathematical reasoning, enabling users to express mathematical queries in plain language and receive step-by-step solutions and insights.The Tabular Data Assistants allows users to ask natural language questions about tabular data stored in CSV files and extract insights from structured datasets with the ability to filter, aggregate, and perform computations on CSV data. The key strength of Agents lies in their ability to autonomously reason about tasks, decompose them into steps, and determine the appropriate tools and data sources to leverage, all without the need for predefined task definitions or rigid workflows.The Math Assistant and Tabular Data assistant are being released in preview mode as we continue to evaluate and mitigate the potential risks associated with autonomous reasoning Agents, such as misuse of external tools, lack of transparency, biased outputs, privacy concerns, and remote code execution vulnerabilities. With future release we plan work to enhance the safety and robustness of these autonomous reasoning capabilities.

## Customization and Personalization

**User-Selectable Options:** Users can fine-tune their interactions by adjusting settings such as temperature and persona, tailoring the AI experience to their specific needs.

**UX Settings:** Easily tweak behavior and experiment with various options directly in the user interface.

## Enhanced AI Interaction

**Simple File Upload and Status:** We have put uploading of files into the Accelerator in the hands of the users by providing a simple drag-and-drop user interface for adding new content and a status page for monitoring document pre-processing.

**Visualizing Thought Process:** Gain insights into the AI's decision-making process by visualizing how it arrives at answers, providing transparency and control.

**Proper Citations and References:** The platform generates referenceable source content, designed to enhance trustworthiness and accountability in AI-generated responses.

**Image Captioning**: The platform can generate captions for images, providing additional context for the user. **NOTE**:"CAPTION" and "DENSE_CAPTIONS" are only supported in Azure GPU regions (East US, France Central, Korea Central, North Europe, Southeast Asia, West Europe, West US)

## User Experience



![Chat screen](/docs/images/info-assist-chat-ui.png)

The end user leverages the web interface as the primary method to engage with the IA Accelerator, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined on the [User Experience](/docs/features/user_experience.md) page.

## Document Deletion

There are multiple options to for deleting documents in the IA Accelerator. Most users will perform document deletion in the UI, while experience technical users may opt for deleting files through the underlying infrastructure.

### File Deletion in the UI

Users can delete documents through the same Manage Content UI they use to review the status of files they have uploaded. Follow the steps outlined below to delete files:

1. __Access the Manage Content UI__: Select the __Manage Content__ tab located at the top right.
2. __Filter Your Files__: On the left, select __Upload Status__ then use the dropdown lists to apply any desired filters.
3. __Refresh the List__: Click the __Refresh__ icon to update the list of files based on your filters.
4. __Delete a File__: Once the filtered list appears, select the file you want to delete. Then, click the __Delete__ link located to the right of the Refresh link.

![Upload Status](/docs/images/upload-status-delete.png)

### Technical File Deletion from the upload container

An experienced technical user can delete a document from the upload container in the `infoasststore*****` Storage Account. The Azure Function `FileDeletion` runs on an interval timer and will delete the relevant documents from the content Storage container, the AI Search Index, and CosmosDB. It will then update the state of the document, which can be viewed in the Upload Status portion of the UI under the Manage Content tab at the top right.

## Works in Progress (Future releases)

### Image Similarity Search

We've starting with text-based image retrieval, but in the future, we have plans to extend this functionality to include image-to-image search, offering even more robust options for our users.

### Adding Evaluation Guidance and Metrics

To ensure transparency and accountability, we are researching comprehensive evaluation guidance and metrics. This will assist users in assessing the performance and trustworthiness of AI-generated responses, fostering confidence in the platform.


