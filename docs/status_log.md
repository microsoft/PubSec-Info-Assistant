# Status Logger

To provide a simple and consumable status log to features such as the web UI, we output processing progress status to a log file for each file processed in Cosmos DB. This functionality is within the file called status_log.py. It creates a JSON document for each file processed and then updates as a new status item is achieved and by default, these files are in the Informaion_assistant database and the status container with it. Below is an example of a status document. The id is a base64 encoding of the file name. This is used as the partition key. The reason for the encoding is if the file name includes any invalid characters that would raise an error when trying to use as a partition key.

Currently the status logger provides a class, StatusLog, with the following functions:

- **upsert_document** - this function will insert or update a status entry in the Cosmos DB instance if you supply the document id and the status you wish to log. Please note the document id is generated using the encode_document_id function
- **encode_document_id** - this function is used to generate the id from the file name by the upsert_document function initially. It can also be called to retrieve the encoded id of a file if you pass in the file name. The id is used as the partition key.
- **read_documents** - This function returns status documents from Cosmos DB for you to use. You can specify optional query parameters, such as document id (the document path) or an integer representing how many minutes from now the processing should have started, or if you wish to receive verbose or concise details.

Finally you will need to supply 4 properties to the class before you can call the above functions. These are COSMOSDB_URL, COSMOSDB_KEY, COSMOSDB_LOG_DATABASE_NAME and COSMOSDB_LOG_CONTAINER_NAME. The resulting json includes verbos status updates but also a snapshot status for the end user UI, specifically the state, state_description and state_timestamp. These values are just select high level state snapshots, including 'Processing', 'Error' and 'Complete'.

````json
{
    "id": "dXBsb2FkL25hbi90ZXN0X2Nhc2UucGRm",
    "file_path": "upload/nan/test_case.pdf",
    "file_name": "test_case.pdf",
    "state": "Complete",
    "state_description": "",
    "state_timestamp": "2023-06-13 21:40:18",
    "status_updates": [
        {
            "status": "File Uploaded",
            "status_timestamp": "2023-06-13 21:40:05",
            "status_classification": "Info"
        },
        {
            "status": "Parser function started",
            "status_timestamp": "2023-06-13 21:40:05",
            "status_classification": "Info"
        },
        {
            "status": "Analyzing PDF",
            "status_timestamp": "2023-06-13 21:40:05",
            "status_classification": "Info"
        },
        {
            "status": "Calling Form Recognizer",
            "status_timestamp": "2023-06-13 21:40:06",
            "status_classification": "Info"
        },
        {
            "status": "Form Recognizer response received",
            "status_timestamp": "2023-06-13 21:40:18",
            "status_classification": "Info"
        },
        {
            "status": "Starting document map build",
            "status_timestamp": "2023-06-13 21:40:18",
            "status_classification": "Info"
        },
        {
            "status": "Starting document map build complete, starting chunking",
            "status_timestamp": "2023-06-13 21:40:21",
            "status_classification": "Info"
        },
        {
            "status": "Chunking complete",
            "status_timestamp": "2023-06-13 21:40:23",
            "status_classification": "Info"
        },
        {
            "status": "Chunking complete",
            "status_timestamp": "2023-06-13 21:40:23",
            "status_classification": "Info"
        },
        {
            "status": "Processing complete",
            "status_timestamp": "2023-06-13 21:40:23",
            "status_classification": "Info"
        }
    ],
    "_rid": "u05JAIH9a5A3AAAAAAAAAA==",
    "_self": "dbs/u05JAA==/colls/u05JAIH9a5A=/docs/u05JAIH9a5A3AAAAAAAAAA==/",
    "_etag": "\"6000c1b2-0000-0d00-0000-6488d4390000\"",
    "_attachments": "attachments/",
    "_ts": 1686688825
}
````