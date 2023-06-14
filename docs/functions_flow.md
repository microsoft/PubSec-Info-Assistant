# Functions Flow
This document outlines the flow of data through the various functions and queues to pre-process the files. Blow is an outline of this flow.

## Diagram
![Process Flow](images/func-flow.png)

Initially files are uploaded manually, or via the UI, to the upload container in your Azure Storage Account. The action of completing teh upload triggers the first function in the chain, **FileUploadedFunc**. This function is responsible for reading the file in and determining the type of file, PDF, DocX, HTML etc. It will then post a message to the **non-pdf-submit-queue** or **pdf-submit-queue** depending on the file type. This will then allow these files to be processed differently depending on their type.

Listening to the **pdf-submit-queue** is a function called **FileFormRecSubmissionPDF**. This will pick up the PDF file and try to submit it to Azure Form Recognizer for processing. If this is successful it will receive an ID from Azure Form Recognizer which can be used to poll Azure Form Recognizer to receive the processed results once processing is completed. At the point it will submit a message indicating this information to the **pdf-polling-queue**. If it is not successful, a message is sent back to the **pdf-submit-queue**. However, this message is configured to not be visible to the function to pick up again for delay period specified in the function, which increases exponentially up to a maximum delay and maximum number of retries.

Now that the message is in the **pdf-polling-queue**, the next function picks this message up and attempts to process it. The **FileFormRecPollingPDF** reaches out to Azure Form Recognizer with the id of the process and attempts to retrieve the results. if the service is still processing, which can take minutes for large files, the function closes down and the message returns to the queue with a delay before the function picks up the message and retries.Again, after a maximum number fo retries, the document will be logged with a status or error. If the results are received, then the function will create the document map, a standard representation of the document, and this is then passed to the shared code functions to generate chunks.

The other main path through the flow is for non-PDF files. The **FileLayoutParsingOther** function listens to the **non-pdf-submit-queue** and starts processing new messages when they are received. this will convert DocX to html, if the file type is html or htm, and then it will build the same document map structure as was created for PDF files. Likewise, this function will call the same shared code functions to generate the chunks.

## References
- [Form Recognizer service quotas and limits](https://learn.microsoft.com/en-us/azure/applied-ai-services/form-recognizer/service-limits?view=form-recog-3.0.0)
- [Cognitive Services autoscale feature](https://learn.microsoft.com/en-us/azure/cognitive-services/autoscale?tabs=portal)
- [Form Recognizer 2023-02-28-preview API Reference](https://westus.dev.cognitive.microsoft.com/docs/services/form-recognizer-api-2023-02-28-preview/operations/AnalyzeDocument)
- [QueuesOptions.VisibilityTimeout Property](https://learn.microsoft.com/en-us/dotnet/api/microsoft.azure.webjobs.host.queuesoptions.visibilitytimeout?view=azure-dotnet)
