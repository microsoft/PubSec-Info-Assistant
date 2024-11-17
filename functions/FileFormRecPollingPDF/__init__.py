# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import logging
import os
import json
import random
import time
import requests
from minio import Minio
from minio.error import S3Error
from requests.exceptions import RequestException
from tenacity import retry, stop_after_attempt, wait_fixed
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities, MediaType
import pika

def string_to_bool(s):
    return s.lower() == 'true'

# MinIO configuration
minio_client = Minio(
    os.environ["MINIO_ENDPOINT"],
    access_key=os.environ["MINIO_ACCESS_KEY"],
    secret_key=os.environ["MINIO_SECRET_KEY"],
    secure=False
)
minio_upload_bucket = os.environ["MINIO_UPLOAD_BUCKET"]
minio_output_bucket = os.environ["MINIO_OUTPUT_BUCKET"]
minio_log_bucket = os.environ["MINIO_LOG_BUCKET"]

# RabbitMQ configuration
rabbitmq_host = os.environ["RABBITMQ_HOST"]
rabbitmq_port = int(os.environ["RABBITMQ_PORT"])
rabbitmq_user = os.environ["RABBITMQ_USER"]
rabbitmq_password = os.environ["RABBITMQ_PASSWORD"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]

# Form Recognizer configuration
endpoint = os.environ["FORM_RECOGNIZER_ENDPOINT"]
api_version = os.environ["FR_API_VERSION"]
FR_MODEL = "prebuilt-layout"

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Other configurations
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
max_submit_requeue_count = int(os.environ["MAX_SUBMIT_REQUEUE_COUNT"])
max_polling_requeue_count = int(os.environ["MAX_POLLING_REQUEUE_COUNT"])
submit_requeue_hide_seconds = int(os.environ["SUBMIT_REQUEUE_HIDE_SECONDS"])
polling_backoff = int(os.environ["POLLING_BACKOFF"])
max_read_attempts = int(os.environ["MAX_READ_ATTEMPTS"])
enableDevCode = string_to_bool(os.environ["ENABLE_DEV_CODE"])
local_debug = os.environ["LOCAL_DEBUG"]

# Initialize status log
status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

# Initialize utilities
utilities = Utilities(minio_client, minio_upload_bucket, minio_output_bucket, minio_log_bucket)

def main(ch, method, properties, body):
    try:
        status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)
        message_body = body.decode('utf-8')
        message_json = json.loads(message_body)
        blob_name = message_json['blob_name']
        blob_uri = message_json['blob_uri']
        FR_resultId = message_json['FR_resultId']
        queued_count = message_json['polling_queue_count']
        submit_queued_count = message_json["submit_queued_count"]
        status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Message received from pdf polling queue attempt {queued_count}', StatusClassification.DEBUG, State.PROCESSING)
        status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Polling Form Recognizer function started', StatusClassification.INFO)

        headers = {
            "Content-Type": "application/json",
            'Authorization': f'Bearer {os.environ["FORM_RECOGNIZER_API_KEY"]}'
        }
        params = {
            'api-version': api_version
        }
        url = f"{endpoint}/formrecognizer/documentModels/{FR_MODEL}/analyzeResults/{FR_resultId}"

        response = durable_get(url, headers, params)

        if response.status_code == 200:
            response_json = response.json()
            response_status = response_json['status']

            if response_status == "succeeded":
                status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Form Recognizer has completed processing and the analyze results have been received', StatusClassification.DEBUG)
                status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Starting document map build', StatusClassification.DEBUG)
                document_map = utilities.build_document_map_pdf(blob_name, blob_uri, response_json["analyzeResult"], minio_log_bucket, enableDevCode)
                status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Document map build complete', StatusClassification.DEBUG)
                status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Starting chunking', StatusClassification.DEBUG)
                chunk_count = utilities.build_chunks(document_map, blob_name, blob_uri, CHUNK_TARGET_SIZE)
                status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Chunking complete, {chunk_count} chunks created.', StatusClassification.DEBUG)

                connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
                channel = connection.channel()
                channel.queue_declare(queue=text_enrichment_queue)
                message_json["text_enrichment_queued_count"] = 1
                message_string = json.dumps(message_json)
                channel.basic_publish(exchange='', routing_key=text_enrichment_queue, body=message_string)
                status_log.upsert_document(blob_name, f"FileFormRecPollingPDF - message sent to enrichment queue", StatusClassification.DEBUG, State.QUEUED)
            elif response_status == "running":
                if queued_count < max_read_attempts:
                    backoff = polling_backoff * (queued_count ** 2)
                    backoff += random.randint(0, 10)
                    queued_count += 1
                    message_json['polling_queue_count'] = queued_count
                    status_log.upsert_document(blob_name, f"FileFormRecPollingPDF - FR has not completed processing, requeuing. Polling back off of attempt {queued_count} of {max_polling_requeue_count} for {backoff} seconds", StatusClassification.DEBUG, State.QUEUED)
                    connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
                    channel = connection.channel()
                    channel.queue_declare(queue=pdf_polling_queue)
                    message_json_str = json.dumps(message_json)
                    channel.basic_publish(exchange='', routing_key=pdf_polling_queue, body=message_json_str)
                else:
                    status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - maximum submissions to FR reached', StatusClassification.ERROR, State.ERROR)
            else:
                if submit_queued_count < max_submit_requeue_count:
                    status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - unhandled response from Form Recognizer- code: {response.status_code} status: {response_status} - text: {response.text}. Document will be resubmitted', StatusClassification.ERROR)
                    connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
                    channel = connection.channel()
                    channel.queue_declare(queue=pdf_submit_queue)
                    submit_queued_count += 1
                    message_json["submit_queued_count"] = submit_queued_count
                    message_string = json.dumps(message_json)
                    channel.basic_publish(exchange='', routing_key=pdf_submit_queue, body=message_string)
                    status_log.upsert_document(blob_name, f'FileFormRecPollingPDF file resent to submit queue. Visible in {submit_requeue_hide_seconds} seconds', StatusClassification.DEBUG, State.THROTTLED)
                else:
                    status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - maximum submissions to FR reached', StatusClassification.ERROR, State.ERROR)
        else:
            status_log.upsert_document(blob_name, f'FileFormRecPollingPDF - Error raised by FR polling', StatusClassification.ERROR, State.ERROR)
    except Exception as e:
        status_log.upsert_document(blob_name, f"FileFormRecPollingPDF - An error occurred - code: {response.status_code} - {str(e)}", StatusClassification.ERROR, State.ERROR)
        status_log.save_document(blob_name)

@retry(stop=stop_after_attempt(max_read_attempts), wait=wait_fixed(5))
def durable_get(url, headers, params):
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()  # Raise stored HTTPError, if one occurred.
    return response

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=pdf_polling_queue)
channel.basic_consume(queue=pdf_polling_queue, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()


#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Form Recognizer: Adjusted the endpoint and authorization for the on-premises Form