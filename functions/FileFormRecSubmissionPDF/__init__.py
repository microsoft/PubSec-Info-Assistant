import logging
import azure.functions as func
from azure.storage.blob import generate_blob_sas
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
import logging
import os
import json
import requests
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities
import random


azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
FR_key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]
api_version = os.environ["FR_API_VERSION"]


statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)
utilities = Utilities(azure_blob_storage_account, azure_blob_drop_storage_container, azure_blob_content_storage_container, azure_blob_storage_key)
FR_MODEL = "prebuilt-layout"
MAX_REQUEUE_COUNT = 5   #max times we will retry the submission
POLL_QUEUE_SUBMIT_BACKOFF = 60    # Hold for n seconds to give FR time to process the file
PDF_SUBMIT_QUEUE_BACKOFF = 60 



def main(msg: func.QueueMessage) -> None:
    logging.info('Python queue trigger function processed a queue item: %s',
                 msg.get_body().decode('utf-8'))

    # Receive message from the queue
    message_body = msg.get_body().decode('utf-8')
    message_json = json.loads(message_body)
    blob_path =  message_json['blob_name']
    queued_count =  message_json['submit_queued_count']
    statusLog.upsert_document(blob_path, 'Submitting to Form Recognizer', StatusClassification.INFO)
    statusLog.upsert_document(blob_path, 'Queue message received from pdf submit queue', StatusClassification.DEBUG)

    # construct blob url
    blob_path_plus_sas = utilities.get_blob_and_sas(blob_path)
    statusLog.upsert_document(blob_path, 'SAS token generated', StatusClassification.DEBUG)

    # Construct and submmit the message to FR
    headers = {
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': FR_key
    }

    params = {
        'api-version': api_version
    }
    
    body = {
         "urlSource": blob_path_plus_sas
    }
    url = f"{endpoint}formrecognizer/documentModels/{FR_MODEL}:analyze"
 
    # Send the HTTP POST request with headers, query parameters, and request body
    response = requests.post(url, headers=headers, params=params, json=body)

    # Check if the request was successful (status code 200)
    if response.status_code == 202:
        # Successfully submitted
        statusLog.upsert_document(blob_path, 'PDF submitted to FR successfully', StatusClassification.DEBUG) 
        message_json['FR_resultId'] = response.headers.get("apim-request-id")   
        message_json['polling_queue_count'] = 1     
        queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name=pdf_polling_queue, message_encode_policy=TextBase64EncodePolicy())    
        message_json_str = json.dumps(message_json)    
        queue_client.send_message(message_json_str, visibility_timeout = POLL_QUEUE_SUBMIT_BACKOFF)  
        statusLog.upsert_document(blob_path, 'message sent to polling queue', StatusClassification.DEBUG) 

    elif response.status_code == 429:
        # throttled, so requeue with random backoff seconds to mitigate throttling, unless it has hit the max tries
        if queued_count < MAX_REQUEUE_COUNT:
            max_seconds = PDF_SUBMIT_QUEUE_BACKOFF * (queued_count ** 2)
            backoff =  random.randint(PDF_SUBMIT_QUEUE_BACKOFF * queued_count, max_seconds)
            queued_count += 1
            message_json['queued_count'] = queued_count
            statusLog.upsert_document(blob_path, f"Throttled on PDF submission to FR, requeuing. Back off of {backoff} seconds", StatusClassification.DEBUG) 
            queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name=pdf_submit_queue, message_encode_policy=TextBase64EncodePolicy())   
            message_json_str = json.dumps(message_json)  
            queue_client.send_message(message_json_str, visibility_timeout=backoff)
        else:
            statusLog.upsert_document(blob_path, f'maximum submissions to FR reached', StatusClassification.ERROR, State.ERROR) 

    else:
        # general error occurred
        statusLog.upsert_document(blob_path, f'Error on PDF submission to FR - {response.code} {response.message}', StatusClassification.ERROR, State.ERROR) 