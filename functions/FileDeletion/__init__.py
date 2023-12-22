from azure.cosmos import CosmosClient, exceptions
from azure.storage.blob import BlobServiceClient
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from datetime import datetime, timezone
from enum import Enum
from itertools import islice

import logging, os
from DeleteTimerTrigger.status_log import State, StatusClassification, StatusLog
import azure.functions as func

BLOB_CONN_STRING = os.environ["BLOB_CONN_STRING"]
UPLOAD_CONT_NAME = os.environ["UPLOAD_CONT_NAME"]
CONTENT_CONT_NAME = os.environ["CONTENT_CONT_NAME"]
SEARCH_ENDPOINT = os.environ["SEARCH_ENDPOINT"]
SEARCH_INDEX = os.environ["SEARCH_INDEX"]
SEARCH_KEY = os.environ["SEARCH_KEY"]
COSMOS_URL = os.environ["COSMOS_URL"]
COSMOS_KEY = os.environ["COSMOS_KEY"]
COSMOS_TAG_DB = os.environ["COSMOS_TAG_DB"]
COSMOS_TAG_CONTAINER = os.environ["COSMOS_TAG_CONTAINER"]
COSMOS_STATUS_DB = os.environ["COSMOS_STATUS_DB"]
COSMOS_STATUS_CONTAINER = os.environ["COSMOS_STATUS_CONTAINER"]

# max to delete with one request is 256, so need to break down dictionary
# define a function that chunks a dictionary
def chunks(data, size):
    # create an iterator over the keys
    it = iter(data)
    # loop over the range of the length of the data
    for i in range(0, len(data), size):
        # yield a dictionary with a slice of keys and their values
        yield {k: data [k] for k in islice(it, size)}

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.utcnow().replace(
        tzinfo=timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    connect_str = BLOB_CONN_STRING
    upload_cont_name = UPLOAD_CONT_NAME

    statusLog = StatusLog(COSMOS_URL, COSMOS_KEY, COSMOS_STATUS_DB, COSMOS_STATUS_CONTAINER)

    # Create Blob Service Client

    blob_service_client = BlobServiceClient.from_connection_string(connect_str)

    # Create Container Client for uploaded blobs and list all blobs, including those that are soft-delted
    upload_container_client = blob_service_client.get_container_client(upload_cont_name)
    temp_list = upload_container_client.list_blobs(include="deleted")
    deleted_blobs = []

    # Pull out the soft-deleted blob names
    for blob in temp_list:
        if blob.deleted == True:
            logging.info("\t Deleted Blob name: " + blob.name)
            deleted_blobs.append(blob.name)

    # Sanity check
    logging.info("Deleted blobs are {}".format(deleted_blobs))

    content_container_client = blob_service_client.get_container_client(CONTENT_CONT_NAME)

    blobs_to_delete = {}
    for blob in deleted_blobs:
        content_list = content_container_client.list_blobs(name_starts_with=blob)
        for blob in content_list:
            logging.info("\t Found blob " + blob.name)
            blobs_to_delete[blob.name] = None

    logging.info("Blobs to delete are {}".format(blobs_to_delete))

    logging.info("Total number of Blobs to delete - {}".format(len(blobs_to_delete)))

    chunked_blobs_to_delete = list(chunks(blobs_to_delete, 255))

    logging.info("Number of chunks with blobs to delete - {}".format(len(chunked_blobs_to_delete)))

    for item in chunked_blobs_to_delete:
        content_container_client.delete_blobs(*item)

    service_endpoint = SEARCH_ENDPOINT
    index_name = SEARCH_INDEX
    key = SEARCH_KEY

    search_client = SearchClient(service_endpoint, index_name, AzureKeyCredential(key))

    search_id_list_to_delete = []

    for file_path in blobs_to_delete:
        search_id_list_to_delete.append({"id": StatusLog.encode_document_id(file_path)})

    # for blob in deleted_blobs:
    #     search_response = search_client.search(search_text="*", filter="file_name eq 'upload/{}'".format(blob), include_total_count=True)
    #     logging.info("Number of results for {}: ".format(blob) + str(search_response.get_count()))

    #     for result in search_response:
    #         id_list.append({"id": result["id"]})

    logging.info("Total IDs to delete: {}".format(len(search_id_list_to_delete)))

    if len(search_id_list_to_delete) > 0:
        delete_result = search_client.delete_documents(documents=search_id_list_to_delete)

        for entry in delete_result:
            logging.info("Delete document succeeded: {}".format(entry.succeeded))
            # logging.info("Deleted {} items from index.".format(len(delete_result)))
    else:
        logging.debug("No items to delete from AI Search Index.")

    cosmos_client = CosmosClient(url=COSMOS_URL, credential=COSMOS_KEY)
    database = cosmos_client.get_database_client(COSMOS_TAG_DB)
    container = database.get_container_client(COSMOS_TAG_CONTAINER)

    for doc in deleted_blobs:
        doc_id = statusLog.encode_document_id("upload/{}".format(doc))
        doc_name = "upload/{}".format(doc)

        logging.info("deleting tags item for doc {} \n \t with ID {}".format(doc, doc_id))

        try:
            container.delete_item(item=doc_id, partition_key=doc_name)
            logging.info("deleted tags for document name {}".format(doc_name))
        except exceptions.CosmosResourceNotFoundError:
            logging.info("Tag entry for {} already deleted".format(doc_name))
    
    for doc in deleted_blobs:
        doc_base = os.path.basename(doc)
        doc_path = "upload/{}".format(doc)

        temp_doc_id = statusLog.encode_document_id(doc_path)

        logging.info("Modifying status for doc {} \n \t with ID {}".format(doc_base, temp_doc_id))

        statusLog.upsert_document(doc_path, f'Updating document status post deletion', StatusClassification.INFO, State.DELETED)
        statusLog.save_document(doc_path)