# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import logging
import os
import json
import random
import time
from shared_code.status_log import StatusLog, State, StatusClassification
from minio import Minio
from minio.error import S3Error
from shared_code.utilities_helper import UtilitiesHelper
from urllib.parse import unquote
import pika
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk

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
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
media_submit_queue = os.environ["MEDIA_SUBMIT_QUEUE"]
image_enrichment_queue = os.environ["IMAGE_ENRICHMENT_QUEUE"]
max_seconds_hide_on_upload = int(os.environ["MAX_SECONDS_HIDE_ON_UPLOAD"])

# Elasticsearch configuration
elasticsearch_client = Elasticsearch([os.environ["ELASTICSEARCH_ENDPOINT"]])
elasticsearch_index = os.environ["ELASTICSEARCH_INDEX"]

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Initialize status log
status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

# Initialize utilities helper
utilities_helper = UtilitiesHelper(
    minio_client=minio_client,
    minio_upload_bucket=minio_upload_bucket,
    minio_output_bucket=minio_output_bucket
)

def get_tags_and_upload_to_postgres(minio_client, blob_path):
    """Gets the tags from the blob metadata and uploads them to PostgreSQL"""
    file_name, file_extension, file_directory = utilities_helper.get_filename_and_extension(blob_path)
    path = file_directory + file_name + file_extension
    try:
        blob = minio_client.stat_object(minio_upload_bucket, path)
        tags = blob.metadata.get("tags")
        if tags:
            tags_list = [unquote(tag.strip()) for tag in tags.split(",")]
        else:
            tags_list = []
        status_log.update_document_tags(blob_path, tags_list)
        return tags_list
    except S3Error as err:
        logging.error(f"Error getting tags for blob {blob_path}: {err}")
        return []

def main(ch, method, properties, body):
    """Function to read supported file types and pass to the correct queue for processing"""
    message_body = body.decode("utf-8")
    message_json = json.loads(message_body)
    blob_name = message_json["blob_name"]
    blob_uri = message_json["blob_uri"]
    try:
        time.sleep(random.randint(1, 2))  # add a random delay
        status_log.upsert_document(blob_name, 'Pipeline triggered by Blob Upload', StatusClassification.INFO, State.PROCESSING, False)
        status_log.upsert_document(blob_name, f'FileUploadedFunc - FileUploadedFunc function started', StatusClassification.DEBUG)

        file_extension = os.path.splitext(blob_name)[1][1:].lower()
        if file_extension == 'pdf':
            queue_name = pdf_submit_queue
        elif file_extension in ['htm', 'csv', 'docx', 'eml', 'html', 'md', 'msg', 'pptx', 'txt', 'xlsx', 'xml', 'json']:
            queue_name = non_pdf_submit_queue
        elif file_extension in ['flv', 'mxf', 'gxf', 'ts', 'ps', '3gp', '3gpp', 'mpg', 'wmv', 'asf', 'avi', 'wmv', 'mp4', 'm4a', 'm4v', 'isma', 'ismv', 'dvr-ms', 'mkv', 'wav', 'mov']:
            queue_name = media_submit_queue
        elif file_extension in ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tif', 'tiff']:
            queue_name = image_enrichment_queue
        else:
            logging.info("Unknown file type")
            error_message = f"FileUploadedFunc - Unexpected file type submitted {file_extension}"
            status_log.state_description = error_message
            status_log.upsert_document(blob_name, error_message, StatusClassification.ERROR, State.SKIPPED)
            return

        message = {
            "blob_name": blob_name,
            "blob_uri": blob_uri,
            "submit_queued_count": 1
        }
        message_string = json.dumps(message)

        try:
            blob = minio_client.stat_object(minio_upload_bucket, blob_name)
            metadata = blob.metadata
            do_not_process = metadata.get('do_not_process')
            if do_not_process == 'true':
                status_log.upsert_document(blob_name, 'Further processing cancelled due to do-not-process metadata = true', StatusClassification.DEBUG, State.COMPLETE)
                return
        except S3Error as err:
            logging.error(f"Error getting metadata for blob {blob_name}: {err}")

        try:
            objects = minio_client.list_objects(minio_output_bucket, prefix=blob_name, recursive=True)
            search_id_list_to_delete = []
            for obj in objects:
                minio_client.remove_object(minio_output_bucket, obj.object_name)
                search_id_list_to_delete.append({"id": status_log.encode_document_id(obj.object_name)})

            if search_id_list_to_delete:
                bulk(elasticsearch_client, [{"_op_type": "delete", "_index": elasticsearch_index, "_id": doc["id"]} for doc in search_id_list_to_delete])
                logging.debug("Successfully deleted items from Elasticsearch index.")
            else:
                logging.debug("No items to delete from Elasticsearch index.")
        except S3Error as err:
            logging.error(f"Error deleting objects from MinIO: {err}")

        get_tags_and_upload_to_postgres(minio_client, blob_name)

        connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
        channel = connection.channel()
        channel.queue_declare(queue=queue_name)
        backoff = random.randint(1, max_seconds_hide_on_upload)
        channel.basic_publish(exchange='', routing_key=queue_name, body=message_string, properties=pika.BasicProperties(delivery_mode=2))
        status_log.upsert_document(blob_name, f'FileUploadedFunc - {file_extension} file sent to submit queue. Visible in {backoff} seconds', StatusClassification.DEBUG, State.QUEUED)

    except Exception as err:
        status_log.upsert_document(blob_name, f"FileUploadedFunc - An error occurred - {str(err)}", StatusClassification.ERROR, State.ERROR)

    status_log.save_document(blob_name)

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=minio_upload_bucket)
channel.basic_consume(queue=minio_upload_bucket, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#Elasticsearch: Replaced Azure Cognitive Search with Elasticsearch for search services.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Metadata Handling: Adjusted the metadata handling to work with MinIO.