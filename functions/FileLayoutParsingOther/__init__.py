# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import json
from enum import Enum
from io import BytesIO
import azure.functions as func
from azure.storage.blob import generate_blob_sas
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from azure.identity import ManagedIdentityCredential, AzureAuthorityHosts, DefaultAzureCredential, get_bearer_token_provider
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities, MediaType

import requests

azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_queue_storage_endpoint = os.environ["AZURE_QUEUE_STORAGE_ENDPOINT"]
azure_blob_drop_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_log_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_log_database_name = os.environ["COSMOSDB_LOG_DATABASE_NAME"]
cosmosdb_log_container_name = os.environ["COSMOSDB_LOG_CONTAINER_NAME"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
local_debug = os.environ["LOCAL_DEBUG"]
azure_ai_credential_domain = os.environ["AZURE_AI_CREDENTIAL_DOMAIN"]
azure_openai_authority_host = os.environ["AZURE_OPENAI_AUTHORITY_HOST"]

function_name = "FileLayoutParsingOther"

if azure_openai_authority_host == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD

# When debugging in VSCode, use the current user identity to authenticate with Azure OpenAI,
# Cognitive Search and Blob Storage (no secrets needed, just use 'az login' locally)
# Use managed identity when deployed on Azure.
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude
# the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
if local_debug == "true":
    azure_credential = DefaultAzureCredential(authority=AUTHORITY)
else:
    azure_credential = ManagedIdentityCredential(authority=AUTHORITY)

utilities = Utilities(azure_blob_storage_account, azure_blob_storage_endpoint, azure_blob_drop_storage_container, azure_blob_content_storage_container, azure_credential)

class UnstructuredError(Exception):
    pass

def PartitionFile(file_extension: str, file_url: str):      
    """ uses the unstructured.io libraries to analyse a document
    Returns:
        elements: A list of available models
    """  
    # Send a GET request to the URL to download the file
    response = requests.get(file_url)
    bytes_io = BytesIO(response.content)
    response.close()   
    metadata = [] 
    elements = None
    file_extension_lower = file_extension.lower()
    try:        
        if file_extension_lower == '.csv':
            from unstructured.partition.csv import partition_csv
            elements = partition_csv(file=bytes_io)               
                     
        elif file_extension_lower == '.doc':
            from unstructured.partition.doc import partition_doc
            elements = partition_doc(file=bytes_io) 
            
        elif file_extension_lower == '.docx':
            from unstructured.partition.docx import partition_docx
            elements = partition_docx(file=bytes_io)
            
        elif file_extension_lower == '.eml' or file_extension_lower == '.msg':
            if file_extension_lower == '.msg':
                from unstructured.partition.msg import partition_msg
                elements = partition_msg(file=bytes_io) 
            else:        
                from unstructured.partition.email import partition_email
                elements = partition_email(file=bytes_io)
            metadata.append(f'Subject: {elements[0].metadata.subject}')
            metadata.append(f'From: {elements[0].metadata.sent_from[0]}')
            sent_to_str = 'To: '
            for sent_to in elements[0].metadata.sent_to:
                sent_to_str = sent_to_str + " " + sent_to
            metadata.append(sent_to_str)
            
        elif file_extension_lower == '.html' or file_extension_lower == '.htm':  
            from unstructured.partition.html import partition_html
            elements = partition_html(file=bytes_io) 
            
        elif file_extension_lower == '.md':
            from unstructured.partition.md import partition_md
            elements = partition_md(file=bytes_io)
                       
        elif file_extension_lower == '.ppt':
            from unstructured.partition.ppt import partition_ppt
            elements = partition_ppt(file=bytes_io)
            
        elif file_extension_lower == '.pptx':    
            from unstructured.partition.pptx import partition_pptx
            elements = partition_pptx(file=bytes_io)
            
        elif any(file_extension_lower in x for x in ['.txt', '.json']):
            from unstructured.partition.text import partition_text
            elements = partition_text(file=bytes_io)
            
        elif file_extension_lower == '.xlsx':
            from unstructured.partition.xlsx import partition_xlsx
            elements = partition_xlsx(file=bytes_io)
            
        elif file_extension_lower == '.xml':
            from unstructured.partition.xml import partition_xml
            elements = partition_xml(file=bytes_io)
            
    except Exception as e:
        raise UnstructuredError(f"An error occurred trying to parse the file: {str(e)}") from e
         
    return elements, metadata
    
    

def main(msg: func.QueueMessage) -> None:
    try:
        statusLog = StatusLog(cosmosdb_url, azure_credential, cosmosdb_log_database_name, cosmosdb_log_container_name)
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
              
        
        # Partition the file dependent on file extension
        elements, metadata = PartitionFile(file_extension, blob_path_plus_sas)
        metdata_text = ''
        for metadata_value in metadata:
            metdata_text += metadata_value + '\n'    
        statusLog.upsert_document(blob_name, f'{function_name} - partitioning complete', StatusClassification.DEBUG)
        
        title = ''
        # Capture the file title
        try:
            for i, element in enumerate(elements):
                if title == '' and element.category == 'Title':
                    # capture the first title
                    title = element.text
                    break
        except:
            # if this type of eleemnt does not include title, then process with emty value
            pass
        
        # Chunk the file     
        from unstructured.chunking.title import chunk_by_title
        NEW_AFTER_N_CHARS = 2000
        COMBINE_UNDER_N_CHARS = 1000
        MAX_CHARACTERS = 2750
        chunks = chunk_by_title(elements, multipage_sections=True, new_after_n_chars=NEW_AFTER_N_CHARS, combine_text_under_n_chars=COMBINE_UNDER_N_CHARS, max_characters=MAX_CHARACTERS)   
        statusLog.upsert_document(blob_name, f'{function_name} - chunking complete. {len(chunks)} chunks created', StatusClassification.DEBUG)
                
        subtitle_name = ''
        section_name = ''
        # Complete and write chunks
        for i, chunk in enumerate(chunks):      
            if chunk.metadata.page_number == None:
                page_list = [1]
            else:
                page_list = [chunk.metadata.page_number] 
            # substitute html if text is a table            
            if chunk.category == 'Table':
                chunk_text = chunk.metadata.text_as_html
            else:
                chunk_text = chunk.text
            # add filetype specific metadata as chunk text header
            chunk_text = metdata_text + chunk_text                    
            utilities.write_chunk(blob_name, blob_uri,
                                f"{i}",
                                utilities.token_count(chunk.text),
                                chunk_text, page_list,
                                section_name, title, subtitle_name,
                                MediaType.TEXT
                                )
        
        statusLog.upsert_document(blob_name, f'{function_name} - chunking stored.', StatusClassification.DEBUG)   
        
        # submit message to the text enrichment queue to continue processing                
        queue_client = QueueClient(account_url=azure_queue_storage_endpoint,
                               queue_name=text_enrichment_queue,
                               credential=azure_credential,
                               message_encode_policy=TextBase64EncodePolicy())
        message_json["text_enrichment_queued_count"] = 1
        message_string = json.dumps(message_json)
        queue_client.send_message(message_string)
        statusLog.upsert_document(blob_name, f"{function_name} - message sent to enrichment queue", StatusClassification.DEBUG, State.QUEUED)    
             
    except Exception as e:
        statusLog.upsert_document(blob_name, f"{function_name} - An error occurred - {str(e)}", StatusClassification.ERROR, State.ERROR)

    statusLog.save_document(blob_name)
    