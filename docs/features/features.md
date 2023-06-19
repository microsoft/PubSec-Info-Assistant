# PS Info Assistant Features

* [Document Pre-Processing](#document-pre-processing)
* [User Experience](#user-experience)
  * Having a conversation with your Private Data
  * Ask your data
  * [Analysis Panel](#analysis-panel)
* [Developer Settings](#developer-settings)
  * [Debugging Functions](#debugging-functions)

---

## Document Pre-processing

The Information Assistant Accelerator pre-processes certain document types to allow better understanding of large complex documents. Currently we apply special processing on:

* PDF
* HTML
* DOCX

For more details on how we process each document type click on on the document type in the list above.

We also log the status of the pre-processing in Azure Cosmos DB. View our [Status Logging](../../functions/shared_code/status_log.md) page for more details.

## User Experience

The end user leverages the web interface as the primary method to engage with the IA Accelerator, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined below.

### Uploading documents
You can upload documents in the [supported formats listed above](#document-pre-processing) through the user interface. To do so:
> 1. Click on the Upload Files link in the top of the interface
> ![Upload Link](/docs/images/upload-files-link.jpg)
> 2. Drag files to the user interface, or click to open a browse window
> ![Upload Link Drag and Drop](/docs/images/upload-files-drag-drop.jpg)

### Having a conversation with your data

When you engage with IA Accelerator in the "Chat" method, the system maintains a history for your conversation and will be able to understand the context of your questions from one question to the next.

> You may activate the Chat engagement pattern by choosing the "Chat" link at the top of the page
> ![Chat Link](/docs/images/chat-interface.jpg)

### Ask your data

When you engage with IA Accelerator in the "Ask a question" method, the system does not maintain a history for your conversation. Each question will be treated with on its own as a new and unique query.

> You may activate the **Ask a question** engagement pattern by choosing the "Chat" link at the top of the page
> ![Chat Link](/docs/images/ask-a-question-interface.jpg)

### Analysis Panel

The Analysis Panel in the UX allows the user to explore three details about the answer to their question:

* Thought Process
* Supporting Content
* [Citations](./ux_analysispanel.md#citations)

View the details of the [Analysis Panel](./ux_analysispanel.md) feature or you can click on each section to get more specifics of that detail tab.

## Developer Settings

### Debugging functions

Check out how to [Debug the Azure functions locally in VSCode](https://learn.microsoft.com/azure/cognitive-services/openai/overview)
