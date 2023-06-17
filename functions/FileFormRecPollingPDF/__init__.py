import logging
import azure.functions as func
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from azure.core.credentials import AzureKeyCredential
from azure.storage.queue import QueueClient
import logging
import os
from enum import Enum
from decimal import Decimal
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
XY_ROUNDING_FACTOR = int(os.environ["XY_ROUNDING_FACTOR"])
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
REAL_WORDS_TARGET = Decimal(os.environ["REAL_WORDS_TARGET"])
FR_API_VERSION = os.environ["FR_API_VERSION"]
# ALL or Custom page numbers for multi-page documents(PDF/TIFF). Input the page numbers and/or
# ranges of pages you want to get in the result. For a range of pages, use a hyphen, like pages="1-3, 5-6".
# Separate each page number or range with a comma.
TARGET_PAGES = os.environ["TARGET_PAGES"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
FR_key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]
api_version = os.environ["FR_API_VERSION"]


statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)
utilities = Utilities(azure_blob_storage_account, azure_blob_drop_storage_container, azure_blob_content_storage_container, azure_blob_storage_key)
FR_MODEL = "prebuilt-layout"
MAX_REQUEUE_COUNT = 5   #max times we will retry the submission


def main(msg: func.QueueMessage) -> None:
    logging.info('Python queue trigger function processed a queue item: %s',
                 msg.get_body().decode('utf-8'))

    # Receive message from the queue
    message_body = msg.get_body().decode('utf-8')
    message_json = json.loads(message_body)
    blob_path =  message_json['blob_name']
    FR_resultId = message_json['FR_resultId']
    statusLog.upsert_document(blob_path, 'Polling Form Recognizer', StatusClassification.INFO)
    statusLog.upsert_document(blob_path, 'Queue message received from pdf polling queue', StatusClassification.DEBUG)
    
    # Construct and submmit the polling message to FR
    headers = {
        'Ocp-Apim-Subscription-Key': FR_key
    }

    params = {
        'api-version': api_version
    }
    
    url = f"{endpoint}formrecognizer/documentModels/{FR_MODEL}/analyzeResults/{FR_resultId}"
 
    # Send the HTTP POST request with headers, query parameters, and request body
    response = requests.get(url, headers=headers, params=params)
    statusLog.upsert_document(blob_path, 'FR response received', StatusClassification.DEBUG)
    
    
    
    
    
    
    # dump detail
    root_folder = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(root_folder, 'responses.txt')
    with open(file_path, 'w') as file:
        response_code = response.status_code
        file.write(f"Response Code: {response_code}\n")
        response_headers = response.headers
        file.write(str(response_headers) + '\n')
        response_body = response.text
        file.write(response_body + '\n')  
