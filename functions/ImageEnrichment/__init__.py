# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import json
import logging
import os
import requests
from minio import Minio
from minio.error import S3Error
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities, MediaType
from elasticsearch import Elasticsearch
from datetime import datetime
import pika

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
image_enrichment_queue = os.environ["IMAGE_ENRICHMENT_QUEUE"]

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
api_detect_endpoint = f"{azure_ai_endpoint}language/:analyze-text?api-version=2023-04-01"
api_translate_endpoint = f"{azure_ai_endpoint}translator/text/v3.0/translate?api-version=3.0"
max_chars_for_detection = 1000

translator_api_headers = {
    "Ocp-Apim-Subscription-Key": azure_ai_key,
    "Content-type": "application/json",
    "Ocp-Apim-Subscription-Region": azure_ai_location,
}

if azure_ai_location in ["eastus", "francecentral", "koreacentral", "northeurope", "southeastasia", "westeurope", "westus"]:
    gpu_region = True
    vision_endpoint = f"{azure_ai_endpoint}computervision/imageanalysis:analyze?api-version=2023-04-01-preview&features=caption,denseCaptions,objects,tags,read&gender-neutral-caption=true"
else:
    gpu_region = False
    vision_endpoint = f"{azure_ai_endpoint}computervision/imageanalysis:analyze?api-version=2023-04-01-preview&features=objects,tags,read&gender-neutral-caption=true"

vision_api_headers = {
    "Ocp-Apim-Subscription-Key": azure_ai_key,
    "Content-type": "application/octet-stream",
    "Accept": "application/json",
    "Ocp-Apim-Subscription-Region": azure_ai_location,
}

function_name = "ImageEnrichment"
utilities = Utilities(
    minio_client=minio_client,
    minio_upload_bucket=minio_upload_bucket,
    minio_output_bucket=minio_output_bucket
)

def detect_language(text):
    data = {
        "kind": "LanguageDetection",
        "analysisInput": {
            "documents": [
                {
                    "id": "1",
                    "text": text[:max_chars_for_detection]
                }
            ]
        }
    }
    response = requests.post(api_detect_endpoint, headers=translator_api_headers, json=data)
    if response.status_code == 200:
        detected_language = response.json()["results"]["documents"][0]["detectedLanguage"]["iso6391Name"]
        detection_confidence = response.json()["results"]["documents"][0]["detectedLanguage"]["confidenceScore"]
        return detected_language, detection_confidence

def translate_text(text, target_language):
    data = [{"text": text}]
    params = {"to": target_language}
    response = requests.post(api_translate_endpoint, headers=translator_api_headers, json=data, params=params)
    if response.status_code == 200:
        translated_content = response.json()[0]["translations"][0]["text"]
        return translated_content
    else:
        raise Exception(response.json())

def main(ch, method, properties, body):
    """This function is triggered by a message in the image-enrichment-queue.
    It will first analyse the image. If the image contains text, it will then
    detect the language of the text and translate it to Target Language. """
    message_body = body.decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    blob_uri = message_json["blob_uri"]
    try:
        status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)
        logging.info("RabbitMQ queue trigger function processed a queue item: %s", body.decode("utf-8"))
        status_log.upsert_document(blob_path, f"{function_name} - Received message from image-enrichment-queue", StatusClassification.DEBUG, State.PROCESSING)
        file_name, file_extension, file_directory = utilities.get_filename_and_extension(blob_path)
        path = blob_path.split("/", 1)[1]
        image_data = minio_client.get_object(minio_upload_bucket, path).read()
        response = requests.post(vision_endpoint, headers=vision_api_headers, data=image_data)

        if response.status_code == 200:
            result = response.json()
            text_image_summary = ""
            index_content = ""
            complete_ocr_text = None
            if gpu_region:
                if result["captionResult"] is not None:
                    text_image_summary += "Caption:\n"
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(result["captionResult"]["text"], result["captionResult"]["confidence"])
                    index_content += "Caption: {}\n ".format(result["captionResult"]["text"])
                if result["denseCaptionsResult"] is not None:
                    text_image_summary += "Dense Captions:\n"
                    index_content += "DeepCaptions: "
                    for caption in result["denseCaptionsResult"]["values"]:
                        text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(caption["text"], caption["confidence"])
                        index_content += "{}\n ".format(caption["text"])
            if result["objectsResult"] is not None:
                text_image_summary += "Objects:\n"
                index_content += "Descriptions: "
                for object_detection in result["objectsResult"]["values"]:
                    text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(object_detection["name"], object_detection["confidence"])
                    index_content += "{}\n ".format(object_detection["name"])
            if result["tagsResult"] is not None:
                text_image_summary += "Tags:\n"
                for tag in result["tagsResult"]["values"]:
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(tag["name"], tag["confidence"])
                    index_content += "{}\n ".format(tag["name"])
            if result["readResult"] is not None:
                text_image_summary += "Raw OCR Text:\n"
                complete_ocr_text = ""
                for line in result["readResult"]["pages"][0]["words"]:
                    complete_ocr_text += "{}\n".format(line["content"])
                text_image_summary += complete_ocr_text
            else:
                logging.error("%s - Image analysis failed for %s: %s", function_name, blob_path, str(response.json()))
                status_log.upsert_document(blob_path, f"{function_name} - Image analysis failed: {str(response.json())}", StatusClassification.ERROR, State.ERROR)
                raise requests.exceptions.HTTPError(response.json())
            if complete_ocr_text not in [None, ""]:
                detected_language, detection_confidence = detect_language(complete_ocr_text)
                text_image_summary += f"Raw OCR Text - Detected language: {detected_language}, Confidence: {detection_confidence}\n"
                if detected_language != target_translation_language:
                    output_text = translate_text(complete_ocr_text, target_translation_language)
                    text_image_summary += f"Translated OCR Text - Target language: {target_translation_language}\n"
                    text_image_summary += output_text
                    index_content += "OCR Text: {}\n ".format(output_text)
                else:
                    output_text = complete_ocr_text
                    index_content += "OCR Text: {}\n ".format(complete_ocr_text)
            else:
                status_log.upsert_document(blob_path, f"{function_name} - No OCR text detected", StatusClassification.INFO, State.PROCESSING)
            utilities.write_chunk(blob_path, blob_uri, 0, utilities.token_count(text_image_summary), text_image_summary, [0], "", file_name, "", MediaType.IMAGE)
            status_log.upsert_document(blob_path, f"{function_name} - Image enrichment is complete", StatusClassification.DEBUG, State.QUEUED)
        except Exception as error:
            status_log.upsert_document(blob_path, f"{function_name} - An error occurred - {str(error)}", StatusClassification.ERROR, State.ERROR)
        try:
            file_name, file_extension, file_directory = utilities.get_filename_and_extension(blob_path)
            path = file_directory + file_name + file_extension
            blob = minio_client.stat_object(minio_upload_bucket, path)
            tags = blob.metadata.get("tags")
            if tags:
                tags_list = [unquote(tag.strip()) for tag in tags.split(",")]
            else:
                tags_list = []
            status_log.update_document_tags(blob_path, tags_list)
            chunk_file = utilities.build_chunk_filepath(file_directory, file_name, file_extension, '0')
            index_section(index_content, file_name, file_directory[:-1], status_log.encode_document_id(chunk_file), chunk_file, blob_path, blob_uri, tags_list)
            status_log.upsert_document(blob_path, f"{function_name} - Image added to index.", StatusClassification.INFO, State.COMPLETE)
        except Exception as err:
            status_log.upsert_document(blob_path, f"{function_name} - An error occurred while indexing - {str(err)}", StatusClassification.ERROR, State.ERROR)
        status_log.save_document(blob_path)

def index_section(index_content, file_name, file_directory, chunk_id, chunk_file, blob_path, blob_uri, tags):
    """ Pushes a batch of content to the search index """
    index_chunk = {}
    batch = []
    index_chunk['id'] = chunk_id
    azure_datetime = datetime.now().astimezone().isoformat()
    index_chunk['processed_datetime'] = azure_datetime
    index_chunk['file_name'] = blob_path
    index_chunk['file_uri'] = blob_uri
    index_chunk['folder'] = file_directory
    index_chunk['title'] = file_name
    index_chunk['content'] = index_content
    index_chunk['pages'] = [0]
    index_chunk['chunk_file'] = chunk_file
    index_chunk['file_class'] = MediaType.IMAGE
    index_chunk['tags'] = tags
    batch.append(index_chunk)
    elasticsearch_client.index(index=elasticsearch_index, body=index_chunk)

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=image_enrichment_queue)
channel.basic_consume(queue=image_enrichment_queue, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#Elasticsearch: Replaced Azure Cognitive Search with Elasticsearch for search services.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Image Analysis: Adjusted the image analysis and text translation logic to work with the on-premises setup.