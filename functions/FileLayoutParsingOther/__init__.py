# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import json
from enum import Enum
from io import BytesIO
import azure.functions as func
from azure.storage.blob import generate_blob_sas
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities
import mammoth
import requests


azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_drop_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
azure_blob_log_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])

statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)
utilities = Utilities(azure_blob_storage_account, azure_blob_storage_endpoint, azure_blob_drop_storage_container, azure_blob_content_storage_container, azure_blob_storage_key)
function_name = "FileLayoutParsingOther"

def main(msg: func.QueueMessage) -> None:
    try:
        logging.info('Python queue trigger function processed a queue item: %s',
                    msg.get_body().decode('utf-8'))

        # Receive message from the queue
        message_body = msg.get_body().decode('utf-8')
        message_json = json.loads(message_body)
        blob_name =  message_json['blob_name']
        blob_uri =  message_json['blob_uri']
        statusLog.upsert_document(blob_name, f'{function_name} - Starting to parse the non-PDF file', StatusClassification.INFO, State.PROCESSING)
        statusLog.upsert_document(blob_name, f'{function_name} - Message received from non-pdf submit queue', StatusClassification.DEBUG)

        # construct blob url
        blob_path_plus_sas = utilities.get_blob_and_sas(blob_name)
        statusLog.upsert_document(blob_name, f'{function_name} - SAS token generated to access the file', StatusClassification.DEBUG)

        file_name, file_extension, file_directory  = utilities.get_filename_and_extension(blob_name)

        response = requests.get(blob_path_plus_sas)
        response.raise_for_status()
        if file_extension in ['.docx']:   
            docx_file = BytesIO(response.content)
            # Convert the downloaded Word document to HTML
            result = mammoth.convert_to_html(docx_file)
            statusLog.upsert_document(blob_name, f'{function_name} - HTML generated from DocX by mammoth', StatusClassification.DEBUG)
            html = result.value # The generated HTML
        else:
            html = response.text 
            
                
        # build the document map from HTML for all non-pdf file types
        statusLog.upsert_document(blob_name, f'{function_name} - Starting document map build', StatusClassification.DEBUG)
        document_map = utilities.build_document_map_html(blob_name, blob_uri, html, azure_blob_log_storage_container)
        statusLog.upsert_document(blob_name, f'{function_name} - Document map build complete, starting chunking', StatusClassification.DEBUG)
        chunk_count = utilities.build_chunks(document_map, blob_name, blob_uri, CHUNK_TARGET_SIZE)
        statusLog.upsert_document(blob_name, f'{function_name} - Chunking complete. {chunk_count} chunks created', StatusClassification.DEBUG, State.COMPLETE)       

    except Exception as e:
        statusLog.upsert_document(blob_name, f"{function_name} - An error occurred - {str(e)}", StatusClassification.ERROR, State.ERROR)
