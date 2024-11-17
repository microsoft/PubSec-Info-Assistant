# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import logging
import os
from datetime import datetime, timezone
from itertools import islice
import schedule
import time
from minio import Minio
from minio.error import S3Error
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk
from shared_code.status_log import State, StatusClassification, StatusLog

# Initialize MinIO client
minio_client = Minio(
    os.environ["MINIO_ENDPOINT"],
    access_key=os.environ["MINIO_ACCESS_KEY"],
    secret_key=os.environ["MINIO_SECRET_KEY"],
    secure=False
)
minio_upload_bucket = os.environ["MINIO_UPLOAD_BUCKET"]
minio_output_bucket = os.environ["MINIO_OUTPUT_BUCKET"]

# Initialize Elasticsearch client
elasticsearch_client = Elasticsearch([os.environ["ELASTICSEARCH_ENDPOINT"]])
elasticsearch_index = os.environ["ELASTICSEARCH_INDEX"]

# PostgreSQL configuration for status logging
postgres_url = os.environ["POSTGRES_URL"]
postgres_log_database_name = os.environ["POSTGRES_LOG_DATABASE_NAME"]
postgres_log_table_name = os.environ["POSTGRES_LOG_TABLE_NAME"]

# Initialize status log
status_log = StatusLog(postgres_url, postgres_log_database_name, postgres_log_table_name)

def chunks(data, size):
    '''max number of blobs to delete in one request is 256, so this breaks
    chunks the dictionary'''
    it = iter(data)
    for i in range(0, len(data), size):
        yield {k: data[k] for k in islice(it, size)}

def get_deleted_blobs(minio_client: Minio) -> list:
    '''Creates and returns a list of file paths that are soft-deleted.'''
    deleted_blobs = []
    try:
        objects = minio_client.list_objects(minio_upload_bucket, recursive=True, include_user_meta=True)
        for obj in objects:
            if obj.is_delete_marker:
                logging.debug("\t Deleted Blob name: %s", obj.object_name)
                deleted_blobs.append(obj.object_name)
    except S3Error as err:
        logging.error("Error listing deleted blobs: %s", err)
    return deleted_blobs

def delete_content_blobs(minio_client: Minio, deleted_blob: str) -> dict:
    '''Deletes blobs in the content container that correspond to a given
    soft-deleted blob from the upload container. Returns a list of deleted
    content blobs for use in other methods.'''
    chunked_blobs_to_delete = {}
    try:
        objects = minio_client.list_objects(minio_output_bucket, prefix=deleted_blob, recursive=True)
        for obj in objects:
            chunked_blobs_to_delete[obj.object_name] = None
        logging.debug("Total number of chunked blobs to delete - %s", str(len(chunked_blobs_to_delete)))
        chunked_content_blob_dict = list(chunks(chunked_blobs_to_delete, 255))
        for item in chunked_content_blob_dict:
            minio_client.remove_objects(minio_output_bucket, item.keys())
    except S3Error as err:
        logging.error("Error deleting content blobs: %s", err)
    return chunked_blobs_to_delete

def delete_search_entries(deleted_content_blobs: dict) -> None:
    '''Takes a list of content blobs that were deleted in a previous
    step and deletes the corresponding entries in the Elasticsearch index.'''
    actions = [
        {
            "_op_type": "delete",
            "_index": elasticsearch_index,
            "_id": status_log.encode_document_id(file_path)
        }
        for file_path in deleted_content_blobs.keys()
    ]
    logging.debug("Total Search IDs to delete: %s", str(len(actions)))
    if actions:
        bulk(elasticsearch_client, actions)
        logging.debug("Successfully deleted items from Elasticsearch index.")
    else:
        logging.debug("No items to delete from Elasticsearch index.")

def main():
    '''This function is a cron job that runs every 10 minutes, detects when 
    a file has been deleted in the upload container and 
    1. removes the generated Blob chunks from the content container, 
    2. removes the PostgreSQL tags entry, and
    3. updates the PostgreSQL logging entry to the Delete state
    If a file has already gone through this process, updates to the code in
    shared_code/status_log.py prevent the status from being continually updated'''
    utc_timestamp = datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
    logging.info('Python timer trigger function ran at %s', utc_timestamp)
    deleted_blobs = get_deleted_blobs(minio_client)
    blob_name = ""
    for blob in deleted_blobs:
        try:
            blob_name = blob
            if status_log.read_file_state(f"upload/{format(blob)}") == State.DELETED:
                logging.info("Blob %s has already been processed.", blob)
                continue
            else:
                deleted_content_blobs = delete_content_blobs(minio_client, blob)
                logging.info("%s content blobs deleted.", str(len(deleted_content_blobs)))
                delete_search_entries(deleted_content_blobs)
                status_log.delete_doc(blob)
                doc_base = os.path.basename(blob)
                doc_path = f"upload/{format(blob)}" 
                temp_doc_id = status_log.encode_document_id(doc_path)
                logging.info("Modifying status for doc %s \n \t with ID %s", doc_base, temp_doc_id)
                status_log.upsert_document(doc_path,
                                           'Document chunks, tags, and entries in Elasticsearch have been deleted',
                                           StatusClassification.INFO,
                                           State.DELETED)
                status_log.save_document(doc_path) 
        except Exception as err:
            logging.info("An exception occurred with doc %s: %s", blob_name, str(err))
            doc_base = os.path.basename(blob)
            doc_path = f"upload/{format(blob)}"
            temp_doc_id = status_log.encode_document_id(doc_path)
            logging.info("Modifying status for doc %s \n \t with ID %s", doc_base, temp_doc_id)
            status_log.upsert_document(doc_path,
                                       f'Error deleting document from system: {str(err)}',
                                       StatusClassification.ERROR,
                                       State.ERROR)
            status_log.save_document(doc_path)

# Schedule the main function to run every 10 minutes
schedule.every(10).minutes.do(main)

while True:
    schedule.run_pending()
    time.sleep(1)

### Key Changes:
#1. **MinIO**: Replaced Azure Blob Storage with MinIO for object storage.
#2. **Elasticsearch**: Replaced Azure Cognitive Search with Elasticsearch for search services.
#3. **PostgreSQL**: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#4. **Scheduling**: Used the `schedule` library to run the function every 10 minutes instead of Azure Functions.