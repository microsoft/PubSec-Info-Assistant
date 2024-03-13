# Status Logger

To provide a status log feature, we output processing progress status to a JSON document for each file processed in Cosmos DB. This functionality is within the file called status_log.py. It creates a JSON document for each file processed and then updates as a new status item. The Cosmos DB entries are stored in the CosmosDB account in the database called statusdb and the container under that database called statuscontainer.

Below is an example of a status document. The id is a base64 encoding of the file name. This is used as the partition key. The reason for the encoding is if the file name includes any invalid characters that would raise an error when trying to use as a partition key.

Currently the status logger provides a class, StatusLog, with the following functions:

- **upsert_document** - this function will insert or update a status entry in the Cosmos DB instance if you supply the document id and the status you wish to log. Please note the document id is generated using the encode_document_id function
- **encode_document_id** - this function is used to generate the id from the file name by the upsert_document function initially. It can also be called to retrieve the encoded id of a file if you pass in the file name. The id is used as the partition key.
- **read_documents** - This function returns status documents from Cosmos DB for you to use. You can specify optional query parameters, such as document id (the document path) or an integer representing how many minutes from now the processing should have started, or if you wish to receive verbose or concise details.

Finally you will need to supply 4 properties to the class before you can call the above functions. These are COSMOSDB_URL, COSMOSDB_KEY, COSMOSDB_LOG_DATABASE_NAME and COSMOSDB_LOG_CONTAINER_NAME. The resulting json includes verbose status updates but also a snapshot status for the end user UI, specifically the state, state_description and state_timestamp. These values are just select high level state snapshots, including 'Processing', 'Error' and 'Complete'.

````json
{
    "id": "dXBsb2FkL0JlbmVmaXRfT3B0aW9ucy5wZGY=",
    "file_path": "upload/Benefit_Options.pdf",
    "file_name": "Benefit_Options.pdf",
    "state": "Complete",
    "start_timestamp": "2024-03-12 22:36:35",
    "state_description": "Embeddings process complete",
    "state_timestamp": "2024-03-12 22:42:40",
    "status_updates": [
        {
            "status": "Pipeline triggered by Blob Upload",
            "status_timestamp": "2024-03-12 22:36:35",
            "status_classification": "Info"
        },
        {
            "status": "FileUploadedFunc - FileUploadedFunc function started",
            "status_timestamp": "2024-03-12 22:36:35",
            "status_classification": "Debug"
        },
        {
            "status": "FileUploadedFunc - pdf file sent to submit queue. Visible in 49 seconds",
            "status_timestamp": "2024-03-12 22:36:35",
            "status_classification": "Debug"
        },
        {
            "status": "FileUploadedFunc - pdf file sent to submit queue. Visible in 24 seconds",
            "status_timestamp": "2024-03-12 22:36:48",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - Received message from pdf-submit-queue ",
            "status_timestamp": "2024-03-12 22:37:15",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - Submitting to Form Recognizer",
            "status_timestamp": "2024-03-12 22:37:15",
            "status_classification": "Info"
        },
        {
            "status": "FileFormRecSubmissionPDF - SAS token generated",
            "status_timestamp": "2024-03-12 22:37:15",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - PDF submitted to FR successfully",
            "status_timestamp": "2024-03-12 22:37:16",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - message sent to pdf-polling-queue. Visible in 60 seconds. FR Result ID is a02f9696-813a-4bda-88cb-c7fa05ad2323",
            "status_timestamp": "2024-03-12 22:37:17",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - Received message from pdf-submit-queue ",
            "status_timestamp": "2024-03-12 22:37:20",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - Submitting to Form Recognizer",
            "status_timestamp": "2024-03-12 22:37:20",
            "status_classification": "Info"
        },
        {
            "status": "FileFormRecSubmissionPDF - SAS token generated",
            "status_timestamp": "2024-03-12 22:37:20",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - PDF submitted to FR successfully",
            "status_timestamp": "2024-03-12 22:37:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecSubmissionPDF - message sent to pdf-polling-queue. Visible in 60 seconds. FR Result ID is 6b26d8b3-f6d1-495d-85cd-23fde40091a9",
            "status_timestamp": "2024-03-12 22:37:22",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Message received from pdf polling queue attempt 1",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Polling Form Recognizer function started",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Info"
        },
        {
            "status": "FileFormRecPollingPDF - Form Recognizer has completed processing and the analyze results have been received",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Starting document map build",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Document map build complete",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Starting chunking",
            "status_timestamp": "2024-03-12 22:39:21",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - Chunking complete, 6 chunks created.",
            "status_timestamp": "2024-03-12 22:39:24",
            "status_classification": "Debug"
        },
        {
            "status": "FileFormRecPollingPDF - message sent to enrichment queue",
            "status_timestamp": "2024-03-12 22:39:24",
            "status_classification": "Debug"
        },
        {
            "status": "TextEnrichment - Received message from text-enrichment-queue ",
            "status_timestamp": "2024-03-12 22:40:17",
            "status_classification": "Debug"
        },
        {
            "status": "TextEnrichment - detected language of text is en.",
            "status_timestamp": "2024-03-12 22:40:17",
            "status_classification": "Debug"
        },
        {
            "status": "TextEnrichment - detected language of text is en.",
            "status_timestamp": "2024-03-12 22:40:17",
            "status_classification": "Debug"
        },
        {
            "status": "TextEnrichment - Text enrichment is complete, message sent to embeddings queue",
            "status_timestamp": "2024-03-12 22:40:20",
            "status_classification": "Debug"
        },
        {
            "status": "TextEnrichment - Text enrichment is complete, message sent to embeddings queue",
            "status_timestamp": "2024-03-12 22:40:20",
            "status_classification": "Debug"
        },
        {
            "status": "Embeddings process started with model azure-openai_text-embedding-ada-002",
            "status_timestamp": "2024-03-12 22:42:37",
            "status_classification": "Info"
        },
        {
            "status": "Embeddings process started with model azure-openai_text-embedding-ada-002",
            "status_timestamp": "2024-03-12 22:42:37",
            "status_classification": "Info"
        },
        {
            "status": "Embeddings process complete",
            "status_timestamp": "2024-03-12 22:42:40",
            "status_classification": "Info"
        }
    ],
    "_rid": "6TgVAOcKcUABAAAAAAAAAA==",
    "_self": "dbs/6TgVAA==/colls/6TgVAOcKcUA=/docs/6TgVAOcKcUABAAAAAAAAAA==/",
    "_etag": "\"1f00fb6b-0000-0d00-0000-65f0da600000\"",
    "_attachments": "attachments/",
    "tags": ["tagname"],
    "_ts": 1710283360
}
````
As mentioned, if you select "Manage Content" from the main page of the Information Assistant you navigate to the page which allows you to upload files. FRom this page select 'Upload Status'. On this Upload Status page you can see processing progress and manage your uploaded content. At the top of the page you can filter your list of files by the folder they are in, the tags you applied during upload, or by the time frame of when they were uploaded from '4 hours' minimum to 'All' which will show all files. By clicking 'Refresh' after selecting your desired filters, the documents matching your criteria will be displayed. In the table of documents you can see the high level file state, a status detail message, the folder it is hosted in and the applied tags. If you wish to delete some files, select a file, multiple files or all files using the selection options on the left column of the table. Then click delete and confirm. You will then see a message in the bottom right of the screen indicating that this process can take up to 10 minutes, so refresh the screen and track progress.

Likewise you can resubmit files, for example if they are in an error state due to an issue such as throttling of the backend services, by selecting the desired files and clicking 'Resubmit'.

Finally, if you wish to see more detail on the actual processing steps of a file, you can simply click on the 'State' column in the table or the 'Status Detail' column. This will show you the detail of the status log from Cosmos DB for the selected file. once this status tab is open, you can select different files from teh table without needing to close this tab.