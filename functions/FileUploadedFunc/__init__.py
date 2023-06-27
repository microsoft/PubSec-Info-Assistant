import logging
import azure.functions as func
from azure.storage.blob import generate_blob_sas
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
import logging
import os
import json
from shared_code.status_log import StatusLog, State, StatusClassification
import random

azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
function_name = "FileUploadedFunc"

statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)


def main(myblob: func.InputStream):
    """ Function to read supported file types and pass to the correct queue for processing"""
    try:
        statusLog.upsert_document(myblob.name, 'File Uploaded', StatusClassification.INFO, State.PROCESSING, True)    
        logging.info(f"Python blob trigger function processed blob \n"
                    f"Name: {myblob.name}\n"
                    f"Blob Size: {myblob.length} bytes")
        
        statusLog.upsert_document(myblob.name, f'{function_name} - FileUploadedFunc function started', StatusClassification.DEBUG)    
        
        # Create message structure to send to queue
      
        file_extension = os.path.splitext(myblob.name)[1][1:].lower()     
        if file_extension == 'pdf':
             # If the file is a PDF a message is sent to the PDF processing queue.
            queue_name = pdf_submit_queue
  
        elif file_extension in ['htm', 'html', 'docx']:
            # Else a message is sent to the non PDF processing queue
            queue_name = non_pdf_submit_queue
                 
        else:
            # Unknown file type
            logging.info("Unknown file type")
            error_message = f"{function_name} - Unexpected file type submitted {file_extension}"
            statusLog.state_description = error_message
            statusLog.upsert_document(myblob.name, error_message, StatusClassification.ERROR, State.SKIPPED) 
            raise Exception(error_message)    
        
        # Create message
        message = {
            "blob_name": f"{myblob.name}",
            "blob_uri": f"{myblob.uri}",
            "submit_queued_count": 1
        }        
        message_string = json.dumps(message)
        
        # Queue message with a random backoff so as not to put the next function under unnecessary load
        queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queue_name, message_encode_policy=TextBase64EncodePolicy())
        backoff =  random.randint(1, 60)        
        queue_client.send_message(message_string, visibility_timeout = backoff)  
        statusLog.upsert_document(myblob.name, f'{function_name} - {file_extension} file sent to submit queue. Visible in {backoff} seconds', StatusClassification.DEBUG, State.QUEUED)          
        
    except Exception as e:
        statusLog.upsert_document(myblob.name, f"{function_name} - An error occurred - {str(e)}", StatusClassification.ERROR, State.ERROR)

