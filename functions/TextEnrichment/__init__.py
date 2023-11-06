import logging
import azure.functions as func
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from azure.storage.blob import BlobServiceClient
from shared_code.utilities import Utilities
import os
import json
import requests
import random
import re
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities

azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_drop_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_log_database_name = os.environ["COSMOSDB_LOG_DATABASE_NAME"]
cosmosdb_log_container_name = os.environ["COSMOSDB_LOG_CONTAINER_NAME"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]
enrichmentKey =  os.environ["ENRICHMENT_KEY"]
enrichmentEndpoint = os.environ["ENRICHMENT_ENDPOINT"] 
targetTranslationLanguage = os.environ["TARGET_TRANSLATION_LANGUAGE"] 
max_requeue_count = int(os.environ["MAX_ENRICHMENT_REQUEUE_COUNT"])
backoff = int(os.environ["ENRICHMENT_BACKOFF"])
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
queueName = os.environ["EMBEDDINGS_QUEUE"]

FUNCTION_NAME = "TextEnrichment"
MAX_CHARS_FOR_DETECTION = 1000


utilities = Utilities(
    azure_blob_storage_account,
    azure_blob_storage_endpoint,
    azure_blob_drop_storage_container,
    azure_blob_content_storage_container,
    azure_blob_storage_key,
)

statusLog = StatusLog(
    cosmosdb_url, cosmosdb_key, cosmosdb_log_database_name, cosmosdb_log_container_name
)     

def main(msg: func.QueueMessage) -> None:
    '''This function is triggered by a message in the text-enrichment-queue.
    It will first determine the language, and if this differs from
    the target language, it will translate the chunks to the target language.'''

    apiDetectEndpoint = "https://api.cognitive.microsofttranslator.{suffix}/detect?api-version=3.0"
    apiTranslateEndpoint = "https://api.cognitive.microsofttranslator.{suffix}/translate?api-version=3.0"

    isGovCloud = 'usgovcloudapi' in azure_blob_storage_endpoint.lower()
    if isGovCloud:
        apiDetectEndpoint = apiDetectEndpoint.format(suffix = "us")
        apiTranslateEndpoint = apiTranslateEndpoint.format(suffix = "us")
    else:
        apiDetectEndpoint = apiDetectEndpoint.format(suffix = "com")
        apiTranslateEndpoint = apiTranslateEndpoint.format(suffix = "com")

    
    message_body = msg.get_body().decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    try:
        
   
        logging.info(
            "Python queue trigger function processed a queue item: %s",
            msg.get_body().decode("utf-8"),
        )
        # Receive message from the queue
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Received message from text-enrichment-queue ",
            StatusClassification.DEBUG,
            State.PROCESSING,
        )
        file_name, file_extension, file_directory  = utilities.get_filename_and_extension(blob_path)
        chunk_folder_path = file_directory + file_name + file_extension
        
        # Detect language of the document
        chunk_content = ''        
        blob_service_client = BlobServiceClient.from_connection_string(azure_blob_connection_string)
        container_client = blob_service_client.get_container_client(azure_blob_content_storage_container)
        # Iterate over the chunks in the container, retrieving up to the max number of chars required
        chunk_list = container_client.list_blobs(name_starts_with=chunk_folder_path)
        chunk_content = ''
        for i, chunk in enumerate(chunk_list):
            # open the file and extract the content
            blob_path_plus_sas = utilities.get_blob_and_sas(azure_blob_content_storage_container + '/' + chunk.name)
            response = requests.get(blob_path_plus_sas)
            response.raise_for_status()
            chunk_dict = json.loads(response.text)   
            if len(chunk_content) + len(chunk_dict["content"]) <= MAX_CHARS_FOR_DETECTION:
                 chunk_content = chunk_content + " " + chunk_dict["content"]
            else:
                # return chars up to the maximum
                remaining_chars = MAX_CHARS_FOR_DETECTION - len(chunk_content)
                chunk_content = chunk_content + " " + trim_content(chunk_dict["content"], remaining_chars)
                break

        # detect language           
        endpoint_region = enrichmentEndpoint.split("https://")[1].split(".api")[0]
        headers = {
            'Ocp-Apim-Subscription-Key': enrichmentKey,
            'Content-type': 'application/json',
            'Ocp-Apim-Subscription-Region': endpoint_region
        }            
        data = [{"text": chunk_content}]

        response = requests.post(apiDetectEndpoint, headers=headers, json=data)      
        if response.status_code == 200:
            detected_language = response.json()[0]['language']
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - detected language of text is {detected_language}.",
                StatusClassification.DEBUG,
                State.QUEUED,
            )             
        else:
            # error or requeue
            requeue(response, message_json)
            return
            
        # If the language of the document is not equal to target language then translate the generated chunks
        if detected_language != targetTranslationLanguage:
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - Non-target language detected",
                StatusClassification.DEBUG,
                State.ERROR,
            )      
               
        # regenerate the iterator to reset it to the first chunk
        chunk_list = container_client.list_blobs(name_starts_with=chunk_folder_path)
        for i, chunk in enumerate(chunk_list):
            # open the file and extract the content
            blob_path_plus_sas = utilities.get_blob_and_sas(azure_blob_content_storage_container + '/' + chunk.name)
            response = requests.get(blob_path_plus_sas)
            response.raise_for_status()
            chunk_dict = json.loads(response.text)
            params = {'to': targetTranslationLanguage}              

            # Translate content, title, subtitle, and section if required
            fields_to_translate = ["content", "title", "subtitle", "section"]
            for field in fields_to_translate:
                translate_and_set(field, chunk_dict, headers, params, message_json, detected_language, targetTranslationLanguage, apiTranslateEndpoint)                
                                            
            # Get path and file name minus the root container
            json_str = json.dumps(chunk_dict, indent=2, ensure_ascii=False)
            block_blob_client = blob_service_client.get_blob_client(container=azure_blob_content_storage_container, blob=chunk.name)
            block_blob_client.upload_blob(json_str, overwrite=True)
                
        # Queue message to embeddings queue for downstream processing
        queue_client = QueueClient.from_connection_string(azure_blob_connection_string, queueName, message_encode_policy=TextBase64EncodePolicy())
        embeddings_queue_backoff =  random.randint(1, 60)
        message_string = json.dumps(message_json)
        queue_client.send_message(message_string, visibility_timeout = embeddings_queue_backoff)
   
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Text enrichment is complete",
            StatusClassification.DEBUG,
            State.QUEUED,
        )
   
    except Exception as error:
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - An error occurred - {str(error)}",
            StatusClassification.ERROR,
            State.ERROR,
        )
        
    statusLog.save_document(blob_path)

def translate_and_set(field_name, chunk_dict, headers, params, message_json, detected_language, targetTranslationLanguage, apiTranslateEndpoint):
    '''Translate text if it is not in target language'''
    if detected_language != targetTranslationLanguage:
        data = [{"text": chunk_dict[field_name]}]
        response = requests.post(apiTranslateEndpoint, headers=headers, json=data, params=params)
        
        if response.status_code == 200:
            translated_content = response.json()[0]['translations'][0]['text']
            chunk_dict[f"translated_{field_name}"] = translated_content
        else:
            # error so requeue
            requeue(response, message_json)
            return   
    else:
        chunk_dict[f"translated_{field_name}"] = chunk_dict[f"{field_name}"]
        return

    
def trim_content(sentence, n):
    '''This function trims a sentence to w max char count and a word boundary'''
    if len(sentence) <= n:
        return sentence
    words = sentence.split()
    trimmed_sentence = ""
    current_length = 0
    for word in words:
        if current_length + len(word) + 1 <= n:
            trimmed_sentence += word + " "
            current_length += len(word) + 1
        else:
            break
    return trimmed_sentence.strip()


def requeue(response, message_json):
    '''This function handles requeing and erroring of cognitive servcies'''
    blob_path = message_json["blob_name"]
    queued_count = message_json["text_enrichment_queued_count"]
    if response.status_code == 429:
        # throttled, so requeue with random backoff seconds to mitigate throttling,
        # unless it has hit the max tries
        if queued_count < max_requeue_count:
            max_seconds = backoff * (queued_count**2)
            backoff = random.randint(
                backoff * queued_count, max_seconds
            )
            queued_count += 1
            message_json["enrichment_queued_count"] = queued_count
            queue_client = QueueClient.from_connection_string(
                azure_blob_connection_string,
                queue_name=text_enrichment_queue,
                message_encode_policy=TextBase64EncodePolicy(),
            )
            message_json_str = json.dumps(message_json)
            queue_client.send_message(message_json_str, visibility_timeout=backoff)
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - message resent to enrichment-queue. Visible in {backoff} seconds.",
                StatusClassification.DEBUG,
                State.QUEUED,
            )       
    else:
        # general error occurred
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Error on language detection - {response.status_code} - {response.reason}",
            StatusClassification.ERROR
        )     