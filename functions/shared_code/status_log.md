# Status Logger

To provide a simple and consumable status log to features such as the web UI, we output processing progress status to a log file for each file processed in Cosmos DB. This functionality is within the file called status_log.py. It creates a JSON document for each file processed and then updates as a new status item is achieved and by default, these files are in the Informaion_assistant database and the status container with it. Below is an example of a status document. The id is a base64 encoding of the file name. This is used as the partition key. The reason for the encoding is if the file name includes any invalid characters that would raise an error when trying to use as a partition key.

Currently the status logger provides a class, StatusLog, with the following functions:

- **upsert_document** - this function will insert or update a status entry in the Cosmos DB instance if you supply the document id and the status you wish to log. Please note the document id is generated using the encode_document_id function
- **encode_document_id** - this function is used to generate the id from the file name by the upsert_document function initially. It can also be called to retrieve the encoded id of a file if you pass in the file name. The id is used as the partition key.

Finally you will need to supply 4 properties to the class before you can call the above functions. These are COSMOSDB_URL, COSMOSDB_KEY, COSMOSDB_DATABASE_NAME and COSMOSDB_CONTAINER_NAME. The resulting json includes verbos status updates but also a snapshot status for the end user UI, specifically the state, state_description and state_timestamp. These values are just select high level state snapshots, including 'Processing', 'Error' and 'Complete'.

````json
{
{
    "id": "dXBsb2FkL25hbi9QZXJrc1BsdXMucGRm",
    "file_path": "upload/nan/PerksPlus.pdf",
    "file_name": "PerksPlus.pdf",
    "state": "Complete",
    "state_description": "",
    "state_timestamp": "2023-06-13 20:47:06",
    "status_updates": [
        {
            "status": "File Uploaded",
            "timestamp": "2023-06-13 20:45:13"
        },
        {
            "status": "Parser function started",
            "timestamp": "2023-06-13 20:45:13"
        },
        {
            "status": "Analyzing PDF",
            "timestamp": "2023-06-13 20:45:37"
        },
        {
            "status": "Calling Form Recognizer",
            "timestamp": "2023-06-13 20:45:38"
        },
        {
            "status": "Form Recognizer response received",
            "timestamp": "2023-06-13 20:45:45"
        },
        {
            "status": "Starting document map build",
            "timestamp": "2023-06-13 20:45:45"
        },
        {
            "status": "Starting document map build complete, starting chunking",
            "timestamp": "2023-06-13 20:45:49"
        },
        {
            "status": "Chunking complete",
            "timestamp": "2023-06-13 20:45:52"
        },
        {
            "status": "Chunking complete",
            "timestamp": "2023-06-13 20:45:52"
        },
        {
            "status": "Processing complete",
            "timestamp": "2023-06-13 20:47:06"
        }
    ]
    "_rid": "apU1AMBOkxELAAAAAAAAAA==",
    "_self": "dbs/apU1AA==/colls/apU1AMBOkxE=/docs/apU1AMBOkxELAAAAAAAAAA==/",
    "_etag": "\"a701b77c-0000-0d00-0000-647f98db0000\"",
    "_attachments": "attachments/",
    "_ts": 1686083803
}
````