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

### Having a conversation with your data

### Ask your data

### Analysis Panel

The Analysis Panel in the UX allows the user to explore three details about the answer to their question:

* Thought Process
* Supporting Content
* [Citations](./ux_analysispanel.md#citations)

View the details of the [Analysis Panel](./ux_analysispanel.md) feature or you can click on each section to get more specifics of that detail tab.

## Developer Settings

### Debugging functions

Check out how to [Debug the Azure functions locally in VSCode](https://learn.microsoft.com/azure/cognitive-services/openai/overview)
