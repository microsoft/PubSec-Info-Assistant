# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import azure.functions as func
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
import logging
import os
import json
import requests
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities, MediaType
import random
from collections import namedtuple
import time
from requests.exceptions import RequestException
from tenacity import retry, stop_after_attempt, wait_fixed

def string_to_bool(s):
    return s.lower() == 'true'

azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_drop_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
azure_blob_log_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"]
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
FR_API_VERSION = os.environ["FR_API_VERSION"]
# ALL or Custom page numbers for multi-page documents(PDF/TIFF). Input the page numbers and/or
# ranges of pages you want to get in the result. For a range of pages, use a hyphen, like pages="1-3, 5-6".
# Separate each page number or range with a comma.
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]
endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
FR_key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]
api_version = os.environ["FR_API_VERSION"]
max_submit_requeue_count = int(os.environ["MAX_SUBMIT_REQUEUE_COUNT"])
max_polling_requeue_count = int(os.environ["MAX_POLLING_REQUEUE_COUNT"])
submit_requeue_hide_seconds = int(os.environ["SUBMIT_REQUEUE_HIDE_SECONDS"])
polling_backoff = int(os.environ["POLLING_BACKOFF"])
max_read_attempts = int(os.environ["MAX_READ_ATTEMPTS"])
enableDevCode = string_to_bool(os.environ["ENABLE_DEV_CODE"])

function_name = "FileFormRecPollingPDF"
utilities = Utilities(azure_blob_storage_account, azure_blob_storage_endpoint, azure_blob_drop_storage_container, azure_blob_content_storage_container, azure_blob_storage_key)
FR_MODEL = "prebuilt-layout"




def main(msg: func.QueueMessage) -> None:
    
    try:
        statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)
        # Receive message from the queue
        message_body = msg.get_body().decode('utf-8')
        message_json = json.loads(message_body)
        blob_name =  message_json['blob_name']
        blob_uri =  message_json['blob_uri']
        FR_resultId = message_json['FR_resultId']
        queued_count = message_json['polling_queue_count']      
        submit_queued_count = message_json["submit_queued_count"]
        statusLog.upsert_document(blob_name, f'{function_name} - Message received from pdf polling queue attempt {queued_count}', StatusClassification.DEBUG, State.PROCESSING)        
        statusLog.upsert_document(blob_name, f'{function_name} - Polling Form Recognizer function started', StatusClassification.INFO)
        
        # Construct and submmit the polling message to FR
        headers = {
            'Ocp-Apim-Subscription-Key': FR_key
        }

        params = {
            'api-version': api_version
        }
        url = f"{endpoint}formrecognizer/documentModels/{FR_MODEL}/analyzeResults/{FR_resultId}"
        
        # retry logic to handle 'Connection broken: IncompleteRead' errors, up to n times
     
        response = durable_get(url, headers, params)   
        
        # Check response and process
        if response.status_code == 200:
            # FR processing is complete OR still running- create document map 
            response_json = response.json()
            response_status = response_json['status']
            
            if response_status == "succeeded":
                # successful, so continue to document map and chunking
                statusLog.upsert_document(blob_name, f'{function_name} - Form Recognizer has completed processing and the analyze results have been received', StatusClassification.DEBUG)  
                # build the document map     
                statusLog.upsert_document(blob_name, f'{function_name} - Starting document map build', StatusClassification.DEBUG)  
                document_map = utilities.build_document_map_pdf(blob_name, blob_uri, response_json["analyzeResult"], azure_blob_log_storage_container)  
                statusLog.upsert_document(blob_name, f'{function_name} - Document map build complete', StatusClassification.DEBUG)     
                # create chunks
                statusLog.upsert_document(blob_name, f'{function_name} - Starting chunking', StatusClassification.DEBUG)  
                chunk_count = utilities.build_chunks(document_map, blob_name, blob_uri, CHUNK_TARGET_SIZE)
                statusLog.upsert_document(blob_name, f'{function_name} - Chunking complete, {chunk_count} chunks created.', StatusClassification.DEBUG)  
                
                # submit message to the enrichment queue to continue processing                
                queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name=text_enrichment_queue, message_encode_policy=TextBase64EncodePolicy())
                message_json["text_enrichment_queued_count"] = 1
                message_string = json.dumps(message_json)
                queue_client.send_message(message_string)
                statusLog.upsert_document(blob_name, f"{function_name} - message sent to enrichment queue", StatusClassification.DEBUG, State.QUEUED) 

            elif response_status == "running":
                # still running so requeue with a backoff
                if queued_count < max_read_attempts:
                    backoff = polling_backoff * (queued_count ** 2)
                    backoff += random.randint(0, 10)
                    queued_count += 1
                    message_json['polling_queue_count'] = queued_count
                    statusLog.upsert_document(blob_name, f"{function_name} - FR has not completed processing, requeuing. Polling back off of attempt {queued_count} of {max_polling_requeue_count} for {backoff} seconds", StatusClassification.DEBUG, State.QUEUED) 
                    queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name=pdf_polling_queue, message_encode_policy=TextBase64EncodePolicy())
                    message_json_str = json.dumps(message_json)  
                    queue_client.send_message(message_json_str, visibility_timeout=backoff)
                else:
                    statusLog.upsert_document(blob_name, f'{function_name} - maximum submissions to FR reached', StatusClassification.ERROR, State.ERROR)     
            else:
                # unexpected status returned by FR, such as internal capacity overload, so requeue
                if submit_queued_count < max_submit_requeue_count:
                    statusLog.upsert_document(blob_name, f'{function_name} - unhandled response from Form Recognizer- code: {response.status_code} status: {response_status} - text: {response.text}. Document will be resubmitted', StatusClassification.ERROR)                  
                    queue_client = QueueClient.from_connection_string(azure_blob_connection_string, pdf_submit_queue, message_encode_policy=TextBase64EncodePolicy())  
                    submit_queued_count += 1
                    message_json["submit_queued_count"] = submit_queued_count
                    message_string = json.dumps(message_json)    
                    queue_client.send_message(message_string, visibility_timeout = submit_requeue_hide_seconds)  
                    statusLog.upsert_document(blob_name, f'{function_name} file resent to submit queue. Visible in {submit_requeue_hide_seconds} seconds', StatusClassification.DEBUG, State.THROTTLED)      
                else:
                    statusLog.upsert_document(blob_name, f'{function_name} - maximum submissions to FR reached', StatusClassification.ERROR, State.ERROR)     
                
        else:
            statusLog.upsert_document(blob_name, f'{function_name} - Error raised by FR polling', StatusClassification.ERROR, State.ERROR)    
                            
    except Exception as e:
        # a general error 
        statusLog.upsert_document(blob_name, f"{function_name} - An error occurred - code: {response.status_code} - {str(e)}", StatusClassification.ERROR, State.ERROR)
        
    statusLog.save_document(blob_name)


@retry(stop=stop_after_attempt(max_read_attempts), wait=wait_fixed(5))
def durable_get(url, headers, params):
    response = requests.get(url, headers=headers, params=params)   
    response.raise_for_status()  # Raise stored HTTPError, if one occurred.
    return response
