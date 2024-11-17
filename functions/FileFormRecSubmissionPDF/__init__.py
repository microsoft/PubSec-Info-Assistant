# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import json
import logging
import os
import random
import requests
from minio import Minio
from minio.error import S3Error
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities
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
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]

# Form Recognizer configuration
endpoint = os.environ["FORM_RECOGNIZER_ENDPOINT"]
api_version = os.environ["FR_API_VERSION"]
FR_MODEL = "prebuilt-layout"

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Other configurations
max_submit_requeue_count = int(os.environ["MAX_SUBMIT_REQUEUE_COUNT"])
poll_queue_submit_backoff = int(os.environ["POLL_QUEUE_SUBMIT_BACKOFF"])
pdf_submit_queue_backoff = int(os.environ["PDF_SUBMIT_QUEUE_BACKOFF"])

# Initialize status log
status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

# Initialize utilities
utilities = Utilities(minio_client, minio_upload_bucket, minio_output_bucket)

def main(ch, method, properties, body):
    """This function is triggered by a message in the pdf-submit-queue.
    It will submit the PDF to Form Recognizer for processing. If the submission
    is throttled, it will requeue the message with a backoff. If the submission
    is successful, it will queue the message to the pdf-polling-queue for polling."""
    message_body = body.decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    try:
        status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)
        queued_count = message_json["submit_queued_count"]
        status_log.upsert_document(
            blob_path,
            f"FileFormRecSubmissionPDF - Received message from pdf-submit-queue ",
            StatusClassification.DEBUG,
            State.PROCESSING,
        )
        status_log.upsert_document(
            blob_path,
            f"FileFormRecSubmissionPDF - Submitting to Form Recognizer",
            StatusClassification.INFO,
        )

        blob_path_plus_sas = utilities.get_blob_and_sas(blob_path)
        status_log.upsert_document(
            blob_path,
            f"FileFormRecSubmissionPDF - SAS token generated",
            StatusClassification.DEBUG,
        )

        headers = {
            "Content-Type": "application/json",
            'Authorization': f'Bearer {os.environ["FORM_RECOGNIZER_API_KEY"]}'
        }
        params = {"api-version": api_version}
        body = {"urlSource": blob_path_plus_sas}
        url = f"{endpoint}/formrecognizer/documentModels/{FR_MODEL}:analyze"
        logging.info(f"Submitting to FR with url: {url}")

        response = requests.post(url, headers=headers, params=params, json=body)

        if response.status_code == 202:
            status_log.upsert_document(
                blob_path,
                f"FileFormRecSubmissionPDF - PDF submitted to FR successfully",
                StatusClassification.DEBUG,
            )
            result_id = response.headers.get("apim-request-id")
            message_json["FR_resultId"] = result_id
            message_json["polling_queue_count"] = 1
            connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
            channel = connection.channel()
            channel.queue_declare(queue=pdf_polling_queue)
            message_json_str = json.dumps(message_json)
            channel.basic_publish(exchange='', routing_key=pdf_polling_queue, body=message_json_str, properties=pika.BasicProperties(delivery_mode=2))
            status_log.upsert_document(
                blob_path,
                f"FileFormRecSubmissionPDF - message sent to pdf-polling-queue. Visible in {poll_queue_submit_backoff} seconds. FR Result ID is {result_id}",
                StatusClassification.DEBUG,
                State.QUEUED,
            )
        elif response.status_code == 429:
            if queued_count < max_submit_requeue_count:
                max_seconds = pdf_submit_queue_backoff * (queued_count**2)
                backoff = random.randint(
                    pdf_submit_queue_backoff * queued_count, max_seconds
                )
                queued_count += 1
                message_json["queued_count"] = queued_count
                status_log.upsert_document(
                    blob_path,
                    f"FileFormRecSubmissionPDF - Throttled on PDF submission to FR, requeuing. Back off of {backoff} seconds",
                    StatusClassification.DEBUG,
                )
                connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
                channel = connection.channel()
                channel.queue_declare(queue=pdf_submit_queue)
                message_json_str = json.dumps(message_json)
                channel.basic_publish(exchange='', routing_key=pdf_submit_queue, body=message_json_str, properties=pika.BasicProperties(delivery_mode=2))
                status_log.upsert_document(
                    blob_path,
                    f"FileFormRecSubmissionPDF - message sent to pdf-submit-queue. Visible in {backoff} seconds.",
                    StatusClassification.DEBUG,
                    State.QUEUED,
                )
            else:
                status_log.upsert_document(
                    blob_path,
                    f"FileFormRecSubmissionPDF - maximum submissions to FR reached",
                    StatusClassification.ERROR,
                    State.ERROR,
                )
        else:
            status_log.upsert_document(
                blob_path,
                f"FileFormRecSubmissionPDF - Error on PDF submission to FR - {response.status_code} - {response.reason}",
                StatusClassification.ERROR,
                State.ERROR,
            )
    except Exception as error:
        status_log.upsert_document(
            blob_path,
            f"FileFormRecSubmissionPDF - An error occurred - {str(error)}",
            StatusClassification.ERROR,
            State.ERROR,
        )

    status_log.save_document(blob_path)

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=pdf_submit_queue)
channel.basic_consume(queue=pdf_submit_queue, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Form Recognizer: Adjusted the endpoint and authorization for the on-premises Form Recognizer.