# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import logging
import os
import json
import random
import requests
from minio import Minio
from minio.error import S3Error
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities
from elasticsearch import Elasticsearch
import pika
from tenacity import retry, stop_after_attempt, wait_fixed

# MinIO configuration
minio_client = Minio(
    os.environ["MINIO_ENDPOINT"],
    access_key=os.environ["MINIO_ACCESS_KEY"],
    secret_key=os.environ["MINIO_SECRET_KEY"],
    secure=False
)
minio_upload_bucket = os.environ["MINIO_UPLOAD_BUCKET"]
minio_output_bucket = os.environ["MINIO_OUTPUT_BUCKET"]

# RabbitMQ configuration
rabbitmq_host = os.environ["RABBITMQ_HOST"]
rabbitmq_port = int(os.environ["RABBITMQ_PORT"])
rabbitmq_user = os.environ["RABBITMQ_USER"]
rabbitmq_password = os.environ["RABBITMQ_PASSWORD"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]
embeddings_queue = os.environ["EMBEDDINGS_QUEUE"]

# Elasticsearch configuration
elasticsearch_client = Elasticsearch([os.environ["ELASTICSEARCH_ENDPOINT"]])
elasticsearch_index = os.environ["ELASTICSEARCH_INDEX"]

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Other configurations
azure_ai_key = os.environ["AZURE_AI_KEY"]
azure_ai_endpoint = os.environ["AZURE_AI_ENDPOINT"]
azure_ai_location = os.environ["AZURE_AI_LOCATION"]
target_translation_language = os.environ["TARGET_TRANSLATION_LANGUAGE"]
max_requeue_count = int(os.environ["MAX_ENRICHMENT_REQUEUE_COUNT"])
enrichment_backoff = int(os.environ["ENRICHMENT_BACKOFF"])
max_chars_for_detection = 1000

translator_api_headers = {
    "Ocp-Apim-Subscription-Key": azure_ai_key,
    "Content-type": "application/json",
    "Ocp-Apim-Subscription-Region": azure_ai_location,
}

api_translate_endpoint = f"{azure_ai_endpoint}translator/text/v3.0/translate?api-version=3.0"
api_language_endpoint = f"{azure_ai_endpoint}language/:analyze-text?api-version=2023-04-01"

function_name = "TextEnrichment"
utilities = Utilities(
    minio_client=minio_client,
    minio_upload_bucket=minio_upload_bucket,
    minio_output_bucket=minio_output_bucket
)

status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

def main(ch, method, properties, body):
    '''This function is triggered by a message in the text-enrichment-queue.
    It will first determine the language, and if this differs from
    the target language, it will translate the chunks to the target language.'''
    message_body = body.decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    try:
        status_log.upsert_document(
            blob_path,
            f"{function_name} - Received message from text-enrichment-queue ",
            StatusClassification.DEBUG,
            State.PROCESSING,
        )
        file_name, file_extension, file_directory = utilities.get_filename_and_extension(blob_path)
        chunk_folder_path = file_directory + file_name + file_extension
        
        chunk_content = '' 
        objects = minio_client.list_objects(minio_output_bucket, prefix=chunk_folder_path, recursive=True)
        for obj in objects:
            response = minio_client.get_object(minio_output_bucket, obj.object_name)
            chunk_dict = json.loads(response.read().decode('utf-8'))
            if len(chunk_content) + len(chunk_dict["content"]) <= max_chars_for_detection:
                chunk_content = chunk_content + " " + chunk_dict["content"]
            else:
                remaining_chars = max_chars_for_detection - len(chunk_content)
                chunk_content = chunk_content + " " + trim_content(chunk_dict["content"], remaining_chars)
                break
        
        headers = {
            "Ocp-Apim-Subscription-Key": azure_ai_key,
            'Content-type': 'application/json',
            'Ocp-Apim-Subscription-Region': azure_ai_location
        }
        
        data = {
            "kind": "LanguageDetection",
            "analysisInput": {
                "documents": [
                    {
                        "id": "1",
                        "text": chunk_content
                    }
                ]
            }
        }
        response = requests.post(api_language_endpoint, headers=headers, json=data) 
        if response.status_code == 200:
            detected_language = response.json()["results"]["documents"][0]["detectedLanguage"]["iso6391Name"]
            status_log.upsert_document(
                blob_path,
                f"{function_name} - detected language of text is {detected_language}.",
                StatusClassification.DEBUG,
                State.PROCESSING
            ) 
        else:
            requeue(response, message_json)
            status_log.save_document(blob_path)
            return
        
        if detected_language != target_translation_language:
            status_log.upsert_document(
                blob_path,
                f"{function_name} - Non-target language detected",
                StatusClassification.DEBUG,
                State.PROCESSING
            ) 
            
            objects = minio_client.list_objects(minio_output_bucket, prefix=chunk_folder_path, recursive=True)
            for obj in objects:
                response = minio_client.get_object(minio_output_bucket, obj.object_name)
                chunk_dict = json.loads(response.read().decode('utf-8'))
                params = {'to': target_translation_language} 
                fields_to_enrich = ["content", "title", "subtitle", "section"]
                for field in fields_to_enrich:
                    translate_and_set(field, chunk_dict, headers, params, message_json, detected_language, target_translation_language, api_translate_endpoint) 
                
                target_content = chunk_dict['translated_title'] + " " + chunk_dict['translated_subtitle'] + " " + chunk_dict['translated_section'] + " " + chunk_dict['translated_content'] 
                enrich_data = {
                    "kind": "EntityRecognition",
                    "parameters": {
                        "modelVersion": "latest"
                    },
                    "analysisInput": {
                        "documents": [
                            {
                                "id": "1",
                                "language": target_translation_language,
                                "text": target_content
                            }
                        ]
                    }
                } 
                response = requests.post(api_language_endpoint, headers=headers, json=enrich_data, params=params)
                try:
                    entities = response.json()['results']['documents'][0]['entities']
                except:
                    entities = []
                entities_collection = []
                for entity in entities:
                    entities_collection.append(entity['text']) 
                chunk_dict["entities"] = entities_collection
                
                enrich_data = {
                    "kind": "KeyPhraseExtraction",
                    "parameters": {
                        "modelVersion": "latest"
                    },
                    "analysisInput": {
                        "documents": [
                            {
                                "id": "1",
                                "language": target_translation_language,
                                "text": target_content
                            }
                        ]
                    }
                } 
                response = requests.post(api_language_endpoint, headers=headers, json=enrich_data, params=params)
                try:
                    key_phrases = response.json()['results']['documents'][0]['keyPhrases']
                except:
                    key_phrases = []
                chunk_dict["key_phrases"] = key_phrases 
                
                json_str = json.dumps(chunk_dict, indent=2, ensure_ascii=False)
                minio_client.put_object(minio_output_bucket, obj.object_name, data=json_str.encode('utf-8'), length=len(json_str))
                
                connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
                channel = connection.channel()
                channel.queue_declare(queue=embeddings_queue)
                embeddings_queue_backoff = random.randint(1, 60)
                message_string = json.dumps(message_json)
                channel.basic_publish(exchange='', routing_key=embeddings_queue, body=message_string, properties=pika.BasicProperties(delivery_mode=2))
                
                status_log.upsert_document(
                    blob_path,
                    f"{function_name} - Text enrichment is complete, message sent to embeddings queue",
                    StatusClassification.DEBUG,
                    State.QUEUED,
                )
    except Exception as error:
        status_log.upsert_document(
            blob_path,
            f"{function_name} - An error occurred - {str(error)}",
            StatusClassification.ERROR,
            State.ERROR,
        )
        status_log.save_document(blob_path)

def translate_and_set(field_name, chunk_dict, headers, params, message_json, detected_language, target_translation_language, api_translate_endpoint):
    '''Translate text if it is not in target language'''
    if detected_language != target_translation_language:
        data = [{"text": chunk_dict[field_name]}]
        response = requests.post(api_translate_endpoint, headers=headers, json=data, params=params)
        
        if response.status_code == 200:
            translated_content = response.json()[0]['translations'][0]['text']
            chunk_dict[f"translated_{field_name}"] = translated_content
        else:
            requeue(response, message_json)
            return 
    else:
        chunk_dict[f"translated_{field_name}"] = chunk_dict[field_name]

def trim_content(sentence, n):
    '''This function trims a sentence to a max char count and a word boundary'''
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
    '''This function handles requeuing and erroring of cognitive services'''
    blob_path = message_json["blob_name"]
    queued_count = message_json["text_enrichment_queued_count"]
    if response.status_code == 429:
        if queued_count < max_requeue_count:
            max_seconds = enrichment_backoff * (queued_count**2)
            backoff = random.randint(enrichment_backoff * queued_count, max_seconds)
            queued_count += 1
            message_json["text_enrichment_queued_count"] = queued_count
            connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
            channel = connection.channel()
            channel.queue_declare(queue=text_enrichment_queue)
            message_json_str = json.dumps(message_json)
            channel.basic_publish(exchange='', routing_key=text_enrichment_queue, body=message_json_str, properties=pika.BasicProperties(delivery_mode=2))
            status_log.upsert_document(blob_path, f"{function_name} - message resent to text enrichment-queue. Visible in {backoff} seconds.", StatusClassification.DEBUG, State.QUEUED)
        else:
            status_log.upsert_document(blob_path, f"{function_name} - maximum submissions to cognitive services reached", StatusClassification.ERROR, State.ERROR)
    else:
        status_log.upsert_document(blob_path, f"{function_name} - Error on language detection - {response.status_code} - {response.reason}", StatusClassification.ERROR, State.ERROR)

@retry(stop=stop_after_attempt(5), wait=wait_fixed(1))
def get_chunk_blob(blob_path_plus_sas):
    '''This function wraps retrieving a blob from storage to allow retries if throttled or error occurs'''
    response = requests.get(blob_path_plus_sas)
    response.raise_for_status()
    return response

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=text_enrichment_queue)
channel.basic_consume(queue=text_enrichment_queue, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#Elasticsearch: Replaced Azure Cognitive Search with Elasticsearch for search services.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Text Enrichment: Adjusted the text enrichment and translation logic to work with the on-premises setup.