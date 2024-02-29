# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
from datetime import datetime, timezone
from itertools import islice
import azure.functions as func
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from azure.storage.blob import BlobServiceClient
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.tags_helper import TagsHelper

blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
blob_storage_account_upload_container_name = os.environ[
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
blob_storage_account_output_container_name = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_search_service_endpoint = os.environ["AZURE_SEARCH_SERVICE_ENDPOINT"]
azure_search_index = os.environ["AZURE_SEARCH_INDEX"]
azure_search_service_key = os.environ["AZURE_SEARCH_SERVICE_KEY"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_log_database_name = os.environ["COSMOSDB_LOG_DATABASE_NAME"]
cosmosdb_log_container_name = os.environ["COSMOSDB_LOG_CONTAINER_NAME"]

status_log = StatusLog(cosmosdb_url,
                       cosmosdb_key,
                       cosmosdb_log_database_name,
                       cosmosdb_log_container_name)

tags_helper = TagsHelper(cosmosdb_url,
                         cosmosdb_key,
                         cosmosdb_log_database_name,
                         cosmosdb_log_container_name)

def chunks(data, size):
    '''max number of blobs to delete in one request is 256, so this breaks
    chunks the dictionary'''
    # create an iterator over the keys
    it = iter(data)
    # loop over the range of the length of the data
    for i in range(0, len(data), size):
        # yield a dictionary with a slice of keys and their values
        yield {k: data [k] for k in islice(it, size)}

def get_deleted_blobs(blob_service_client: BlobServiceClient) -> list:
    '''Creates and returns a list of file paths that are soft-deleted.'''
    # Create Uploaded Container Client and list all blobs, including deleted blobs
    upload_container_client = blob_service_client.get_container_client(
        blob_storage_account_upload_container_name)
    temp_list = upload_container_client.list_blobs(include="deleted")

    deleted_blobs = []
    # Pull out the soft-deleted blob names
    for blob in temp_list:
        if blob.deleted:
            logging.debug("\t Deleted Blob name: %s", blob.name)
            deleted_blobs.append(blob.name)
    return deleted_blobs

def delete_content_blobs(blob_service_client: BlobServiceClient, deleted_blob: str) -> dict:
    '''Deletes blobs in the content container that correspond to a given
    soft-deleted blob from the upload container. Returns a list of deleted
    content blobs for use in other methods.'''
    # Create Content Container Client
    content_container_client = blob_service_client.get_container_client(
        blob_storage_account_output_container_name)
    # Get a dict with all chunked blobs that came from the deleted blob in the upload container
    chunked_blobs_to_delete = {}
    content_list = content_container_client.list_blobs(name_starts_with=deleted_blob)
    for blob in content_list:
        chunked_blobs_to_delete[blob.name] = None
    logging.debug("Total number of chunked blobs to delete - %s", str(len(chunked_blobs_to_delete)))
    # Split the chunked blob dict into chunks of less than 256
    chunked_content_blob_dict = list(chunks(chunked_blobs_to_delete, 255))
    # Delete all of the content blobs that came from a deleted blob in the upload container
    for item in chunked_content_blob_dict:
        content_container_client.delete_blobs(*item)
    return chunked_blobs_to_delete

def delete_search_entries(deleted_content_blobs: dict) -> None:
    '''Takes a list of content blobs that were deleted in a previous
    step and deletes the corresponding entries in the Azure AI 
    Search index.'''
    search_client = SearchClient(azure_search_service_endpoint,
                                 azure_search_index,
                                 AzureKeyCredential(azure_search_service_key))

    search_id_list_to_delete = []
    for file_path in deleted_content_blobs.keys():
        search_id_list_to_delete.append({"id": status_log.encode_document_id(file_path)})

    logging.debug("Total Search IDs to delete: %s", str(len(search_id_list_to_delete)))

    if len(search_id_list_to_delete) > 0:
        search_client.delete_documents(documents=search_id_list_to_delete)
        logging.debug("Succesfully deleted items from AI Search index.")
    else:
        logging.debug("No items to delete from AI Search index.")

def main(mytimer: func.TimerRequest) -> None:
    '''This function is a cron job that runs every 10 miuntes, detects when 
    a file has been deleted in the upload container and 
        1. removes the generated Blob chunks from the content container, 
        2. removes the CosmosDB tags entry, and
        3. updates the CosmosDB logging entry to the Delete state
    If a file has already gone through this process, updates to the code in
    shared_code/status_log.py prevent the status from being continually updated'''
    utc_timestamp = datetime.utcnow().replace(
        tzinfo=timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    # Create Blob Service Client
    blob_service_client = BlobServiceClient.from_connection_string(blob_connection_string)
    deleted_blobs = get_deleted_blobs(blob_service_client)

    blob_name = ""
    try:
        for blob in deleted_blobs:
            blob_name = blob
            deleted_content_blobs = delete_content_blobs(blob_service_client, blob)
            logging.info("%s content blobs deleted.", str(len(deleted_content_blobs)))
            delete_search_entries(deleted_content_blobs)
            tags_helper.delete_doc(blob)

            # for doc in deleted_blobs:
            doc_base = os.path.basename(blob)
            doc_path = f"upload/{format(blob)}"

            temp_doc_id = status_log.encode_document_id(doc_path)

            logging.info("Modifying status for doc %s \n \t with ID %s", doc_base, temp_doc_id)

            status_log.upsert_document(doc_path,
                                    'Document chunks, tags, and entries in AI Search have been deleted',
                                    StatusClassification.INFO,
                                    State.DELETED)
            status_log.save_document(doc_path)
    except Exception as err:
        logging.info("An exception occured with doc %s: %s", blob_name, str(err))
        doc_base = os.path.basename(blob)
        doc_path = f"upload/{format(blob)}"
        temp_doc_id = status_log.encode_document_id(doc_path)
        logging.info("Modifying status for doc %s \n \t with ID %s", doc_base, temp_doc_id)
        status_log.upsert_document(doc_path,
                                f'Error deleting document from system: {str(err)}',
                                StatusClassification.ERROR,
                                State.ERROR)
        status_log.save_document(doc_path)
