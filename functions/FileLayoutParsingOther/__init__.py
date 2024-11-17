# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import logging
import os
import json
from enum import Enum
from io import BytesIO
import requests
from minio import Minio
from minio.error import S3Error
from shared_code.status_log import StatusLog, State, StatusClassification
from shared_code.utilities import Utilities, MediaType
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
minio_log_bucket = os.environ["MINIO_LOG_BUCKET"]

# RabbitMQ configuration
rabbitmq_host = os.environ["RABBITMQ_HOST"]
rabbitmq_port = int(os.environ["RABBITMQ_PORT"])
rabbitmq_user = os.environ["RABBITMQ_USER"]
rabbitmq_password = os.environ["RABBITMQ_PASSWORD"]
non_pdf_submit_queue = os.environ["NON_PDF_SUBMIT_QUEUE"]
text_enrichment_queue = os.environ["TEXT_ENRICHMENT_QUEUE"]

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Other configurations
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])

# Initialize status log
status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

# Initialize utilities
utilities = Utilities(minio_client, minio_upload_bucket, minio_output_bucket, minio_log_bucket)

class UnstructuredError(Exception):
    pass

def PartitionFile(file_extension: str, file_url: str):
    """ uses the unstructured.io libraries to analyse a document
    Returns:
    elements: A list of available models
    """
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

def main(ch, method, properties, body):
    try:
        status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)
        logging.info('RabbitMQ queue trigger function processed a queue item: %s', body.decode('utf-8'))
        message_body = body.decode('utf-8')
        message_json = json.loads(message_body)
        blob_name = message_json['blob_name']
        blob_uri = message_json['blob_uri']
        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - Starting to parse the non-PDF file', StatusClassification.INFO, State.PROCESSING)
        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - Message received from non-pdf submit queue', StatusClassification.DEBUG)
        blob_path_plus_sas = utilities.get_blob_and_sas(blob_name)
        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - SAS token generated to access the file', StatusClassification.DEBUG)
        file_name, file_extension, file_directory = utilities.get_filename_and_extension(blob_name)
        response = requests.get(blob_path_plus_sas)
        response.raise_for_status()

        elements, metadata = PartitionFile(file_extension, blob_path_plus_sas)
        metdata_text = ''
        for metadata_value in metadata:
            metdata_text += metadata_value + '\n'
        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - partitioning complete', StatusClassification.DEBUG)

        title = ''
        try:
            for i, element in enumerate(elements):
                if title == '' and element.category == 'Title':
                    title = element.text
                    break
        except:
            pass

        from unstructured.chunking.title import chunk_by_title
        NEW_AFTER_N_CHARS = 2000
        COMBINE_UNDER_N_CHARS = 1000
        MAX_CHARACTERS = 2750
        chunks = chunk_by_title(elements, multipage_sections=True, new_after_n_chars=NEW_AFTER_N_CHARS, combine_text_under_n_chars=COMBINE_UNDER_N_CHARS, max_characters=MAX_CHARACTERS)
        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - chunking complete. {len(chunks)} chunks created', StatusClassification.DEBUG)

        subtitle_name = ''
        section_name = ''
        for i, chunk in enumerate(chunks):
            if chunk.metadata.page_number == None:
                page_list = [1]
            else:
                page_list = [chunk.metadata.page_number]
            if chunk.category == 'Table':
                chunk_text = chunk.metadata.text_as_html
            else:
                chunk_text = chunk.text
            chunk_text = metdata_text + chunk_text
            utilities.write_chunk(blob_name, blob_uri,
                                  f"{i}",
                                  utilities.token_count(chunk.text),
                                  chunk_text, page_list,
                                  section_name, title, subtitle_name,
                                  MediaType.TEXT)

        status_log.upsert_document(blob_name, f'FileLayoutParsingOther - chunking stored.', StatusClassification.DEBUG)

        connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
        channel = connection.channel()
        channel.queue_declare(queue=text_enrichment_queue)
        message_json["text_enrichment_queued_count"] = 1
        message_string = json.dumps(message_json)
        channel.basic_publish(exchange='', routing_key=text_enrichment_queue, body=message_string)
        status_log.upsert_document(blob_name, f"FileLayoutParsingOther - message sent to enrichment queue", StatusClassification.DEBUG, State.QUEUED)

    except Exception as e:
        status_log.upsert_document(blob_name, f"FileLayoutParsingOther - An error occurred - {str(e)}", StatusClassification.ERROR, State.ERROR)
        status_log.save_document(blob_name)

# RabbitMQ consumer setup
connection = pika.BlockingConnection(pika.ConnectionParameters(host=rabbitmq_host, port=rabbitmq_port, credentials=pika.PlainCredentials(rabbitmq_user, rabbitmq_password)))
channel = connection.channel()
channel.queue_declare(queue=non_pdf_submit_queue)
channel.basic_consume(queue=non_pdf_submit_queue, on_message_callback=main, auto_ack=True)

logging.info('Waiting for messages. To exit press CTRL+C')
channel.start_consuming()

#Key Changes:
#MinIO: Replaced Azure Blob Storage with MinIO for object storage.
#RabbitMQ: Replaced Azure Queue Storage with RabbitMQ for message queuing.
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Partitioning and Chunking: Adjusted the partitioning and chunking logic to use the unstructured library for document analysis.