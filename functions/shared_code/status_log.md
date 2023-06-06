# Status Logger

To provide a simple and consumable status log to features such as the web UI, we output processing progress status to a log file for each file processed in Cosmos DB. This functionality is within the file called status_log.py. It creates a JSON document for each file processed and then updates as a new status item is achieved and by default, these files are in the Informaion_assistant database and the status container with it. Below is an example of a status document. The id is a base64 encoding of the file name. This is used as the partition key. The reason for the encoding is if the file name includes any invalid characters that would raise an error when trying to use as a partition key.

````json
{
    "id": "dXBsb2FkL3dhci1hbmQtcGVhY2UucGRm",
    "file_path": "upload/war-and-peace.pdf",
    "file_name": "war-and-peace.pdf",
    "StatusUpdates": [
        {
            "status": "File Uploaded",
            "datetime": "2023-06-06 21:33:09"
        },
        {
            "status": "Parser function started",
            "datetime": "2023-06-06 21:33:12"
        },
        {
            "status": "Analyzing PDF",
            "datetime": "2023-06-06 21:33:14"
        },
        {
            "status": "Calling Form Recognizer",
            "datetime": "2023-06-06 21:33:16"
        },
        {
            "status": "Form Recognizer response received",
            "datetime": "2023-06-06 21:33:26"
        },
        {
            "status": "Starting document map build",
            "datetime": "2023-06-06 21:33:28"
        },
        {
            "status": "Starting document map build complete, starting chunking",
            "datetime": "2023-06-06 21:33:36"
        },
        {
            "status": "Chunking complete",
            "datetime": "2023-06-06 21:36:42"
        },
        {
            "status": "File processing complete",
            "datetime": "2023-06-06 21:36:44"
        }
    ],
    "_rid": "apU1AMBOkxELAAAAAAAAAA==",
    "_self": "dbs/apU1AA==/colls/apU1AMBOkxE=/docs/apU1AMBOkxELAAAAAAAAAA==/",
    "_etag": "\"a701b77c-0000-0d00-0000-647f98db0000\"",
    "_attachments": "attachments/",
    "_ts": 1686083803
}
````