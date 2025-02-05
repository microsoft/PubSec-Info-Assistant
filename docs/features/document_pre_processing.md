# Document Pre-processing

The Information Assistant relies on a multi-step process to pre-process documents in preparation for them being used in the NLP based chat interface.
The pre-processing of documents is a crucial step as it involves several steps, such as text extraction and normalizing the text, to convert the raw data into a format that can be easily analyzed by the OpenAI model. Information Assistant pre-process different types of documents, ensuring that the text is cleaned and processed effectively for better understanding and analysis of large complex documents.

## Document Pre-Processing

TBD

## Image Pre-Processing

TBD

## Detailed Flow of Pre-Processing

In this section we explore the pre-processing flow in more detail, to enable you to understand the patterns employed and how you may adapt the configuration to meet your own needs. Below is a graphic representing the flow steps..

TBD Graphics need to be added

Initially files are uploaded manually, or via the UI, to the upload container in your Azure Storage Account. The action of completing the upload triggers ... TBD

### Text based files

TBD...

 It determines the primary language of the text by sampling the first few chunks using the [Microsoft Cognitive Services to detect the language.](https://learn.microsoft.com/azure/ai-services/language-service/language-detection/overview). It then iterates through the chunks and translates the textual content. 
 
 This involves creating embeddings to enable vector based search. It generates these embeddings of the textual content of each chunk using the Azure OpenAI model depending on your configuration and writes these back to the chunk. Finally we need to make the enriched chunks available to be searched via the Information Assistant application. TBD... over to the Azure Search Service Index where it will be available to be returned as part of the RAG process.

## AI Search Service Configuration

There are a number of settings that are configured during deployment. Many of the settings relate to hard values, such as storage container names and endpoints for services, but we anticipate customers may wish to change certain configurations and these are described below.

Setting | Description
--- | ---
TBD list from AI Search config 

## References

- [Form Recognizer service quotas and limits](https://learn.microsoft.com/azure/applied-ai-services/form-recognizer/service-limits?view=form-recog-3.0.0)
- [Cognitive Services autoscale feature](https://learn.microsoft.com/azure/cognitive-services/autoscale?tabs=portal)
- [Form Recognizer 2023-02-28-preview API Reference](https://westus.dev.cognitive.microsoft.com/docs/services/form-recognizer-api-2023-02-28-preview/operations/AnalyzeDocument)