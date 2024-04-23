# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import sys
import json
import random
import time
from shared_code.status_log import StatusLog, State, StatusClassification
import azure.functions as func
from azure.storage.blob import BlobServiceClient, generate_blob_sas
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from shared_code.utilities_helper import UtilitiesHelper
from urllib.parse import unquote


azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_log_database_name = os.environ["COSMOSDB_LOG_DATABASE_NAME"]
cosmosdb_log_container_name = os.environ["COSMOSDB_LOG_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
media_submit_queue = os.environ["MEDIA_SUBMIT_QUEUE"]
image_enrichment_queue = os.environ["IMAGE_ENRICHMENT_QUEUE"]
max_seconds_hide_on_upload = int(os.environ["MAX_SECONDS_HIDE_ON_UPLOAD"])
azure_blob_content_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_key = os.environ["AZURE_BLOB_STORAGE_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
azure_blob_upload_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_search_service_endpoint = os.environ["AZURE_SEARCH_SERVICE_ENDPOINT"]
azure_search_service_index = os.environ["AZURE_SEARCH_INDEX"]
azure_search_service_key = os.environ["AZURE_SEARCH_SERVICE_KEY"]





function_name = "FileUploadedFunc"
utilities_helper = UtilitiesHelper(
    azure_blob_storage_account=azure_storage_account,
    azure_blob_storage_endpoint=azure_blob_endpoint,
    azure_blob_storage_key=azure_blob_key,
)
statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_log_database_name, cosmosdb_log_container_name)


def get_tags_and_upload_to_cosmos(blob_service_client, blob_path):
    """ Gets the tags from the blob metadata and uploads them to cosmos db"""
    file_name, file_extension, file_directory = utilities_helper.get_filename_and_extension(blob_path)
    path = file_directory + file_name + file_extension
    blob_client = blob_service_client.get_blob_client(blob=path)
    blob_properties = blob_client.get_blob_properties()
    tags = blob_properties.metadata.get("tags")
    if tags != '' and tags is not None:
        if isinstance(tags, str):
            tags_list = [unquote(tag.strip()) for tag in tags.split(",")]
        else:
            tags_list = [unquote(tag.strip()) for tag in tags]
    else:
        tags_list = []
    # Write the tags to cosmos db
    statusLog.update_document_tags(blob_path, tags_list)
    return tags_list


def main(myblob: func.InputStream):
    """ Function to read supported file types and pass to the correct queue for processing"""

    try:
        time.sleep(random.randint(1, 2))  # add a random delay
        statusLog.upsert_document(myblob.name, 'Pipeline triggered by Blob Upload', StatusClassification.INFO, State.PROCESSING, False)            
        statusLog.upsert_document(myblob.name, f'{function_name} - FileUploadedFunc function started', StatusClassification.DEBUG)    
        
        # Create message structure to send to queue
      
        file_extension = os.path.splitext(myblob.name)[1][1:].lower()
        if file_extension == 'pdf':
             # If the file is a PDF a message is sent to the PDF processing queue.
            queue_name = pdf_submit_queue
  
        elif file_extension in ['htm', 'csv', 'doc', 'docx', 'eml', 'html', 'md', 'msg', 'ppt', 'pptx', 'txt', 'xlsx', 'xml', 'json']:
            # Else a message is sent to the non PDF processing queue
            queue_name = non_pdf_submit_queue
            
        elif file_extension in ['flv', 'mxf', 'gxf', 'ts', 'ps', '3gp', '3gpp', 'mpg', 'wmv', 'asf', 'avi', 'wmv', 'mp4', 'm4a', 'm4v', 'isma', 'ismv', 'dvr-ms', 'mkv', 'wav', 'mov']:
            # Else a message is sent to the Media processing queue
            queue_name = media_submit_queue
        
        elif file_extension in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tif', 'tiff']:
            # Else a message is sent to the Image processing queue
            queue_name = image_enrichment_queue
                 
        else:
            # Unknown file type
            logging.info("Unknown file type")
            error_message = f"{function_name} - Unexpected file type submitted {file_extension}"
            statusLog.state_description = error_message
            statusLog.upsert_document(myblob.name, error_message, StatusClassification.ERROR, State.SKIPPED) 
        
        # Create message
        message = {
            "blob_name": f"{myblob.name}",
            "blob_uri": f"{myblob.uri}",
            "submit_queued_count": 1
        }        
        message_string = json.dumps(message)
        
        blob_client = BlobServiceClient(
            account_url=azure_blob_endpoint,
            credential=azure_blob_key,
        )    

        # Check if the blob has been marked as 'do not process' and abort if so
        # This metadata is set if the blob is already processed and the content from
        # an existing resource group is simply being copied into this resource group
        # as part of a miration. In this case the blob has alreday been enriched and indexed
        # and so no further processing is required on import
        upload_blob_client = blob_client.get_blob_client(container=azure_blob_upload_container, blob=myblob.name)
        properties = upload_blob_client.get_blob_properties()
        metadata = properties.metadata
        do_not_process = metadata.get('do-not-process')   
        if 'do-not-process' in metadata:
            if do_not_process == 'true':   
                statusLog.upsert_document(myblob.name,'Further procesiang cancelled due to do-not-process metadata = true', StatusClassification.DEBUG, State.COMPLETE)   
                sys.exit()                    
        
        # If this is an update to the blob, then we need to delete any residual chunks
        # as processing will overlay chunks, but if the new file version is smaller
        # than the old, then the residual old chunks will remain. The following
        # code handles this for PDF and non-PDF files.
        
        blob_container = blob_client.get_container_client(azure_blob_content_container)
        # List all blobs in the container that start with the name of the blob being processed
        # first remove the container prefix
        myblob_filename = myblob.name.split("/", 1)[1]
        blobs = blob_container.list_blobs(name_starts_with=myblob_filename)
        
        # instantiate the search sdk elements
        search_client = SearchClient(azure_search_service_endpoint,
                                azure_search_service_index,
                                AzureKeyCredential(azure_search_service_key))
        search_id_list_to_delete = []
        
        # Iterate through the blobs and delete each one from blob and the search index
        for blob in blobs:
            blob_client.get_blob_client(container=azure_blob_content_container, blob=blob.name).delete_blob()
            search_id_list_to_delete.append({"id": statusLog.encode_document_id(blob.name)})
        
        if len(search_id_list_to_delete) > 0:
            search_client.delete_documents(documents=search_id_list_to_delete)
            logging.debug("Succesfully deleted items from AI Search index.")
        else:
            logging.debug("No items to delete from AI Search index.")        
            
        # write tags to cosmos db once per file/message
        blob_service_client = BlobServiceClient.from_connection_string(azure_blob_connection_string)
        upload_container_client = blob_service_client.get_container_client(azure_blob_upload_container)
        tag_list = get_tags_and_upload_to_cosmos(upload_container_client, myblob.name)
        
        # Queue message with a random backoff so as not to put the next function under unnecessary load
        queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name, message_encode_policy=TextBase64EncodePolicy())
        backoff =  random.randint(1, max_seconds_hide_on_upload)        
        queue_client.send_message(message_string, visibility_timeout = backoff)  
        statusLog.upsert_document(myblob.name, f'{function_name} - {file_extension} file sent to submit queue. Visible in {backoff} seconds', StatusClassification.DEBUG, State.QUEUED)          
        
    except Exception as err:
        statusLog.upsert_document(myblob.name, f"{function_name} - An error occurred - {str(err)}", StatusClassification.ERROR, State.ERROR)

    statusLog.save_document(myblob.name)