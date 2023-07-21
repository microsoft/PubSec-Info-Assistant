# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import os
import random

import azure.functions as func
import requests
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities

azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
pdf_polling_queue = os.environ["PDF_POLLING_QUEUE"]
pdf_submit_queue = os.environ["PDF_SUBMIT_QUEUE"]
endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
FR_key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]
api_version = os.environ["FR_API_VERSION"]
max_submit_requeue_count = int(os.environ["MAX_SUBMIT_REQUEUE_COUNT"])
poll_queue_submit_backoff = int(os.environ["POLL_QUEUE_SUBMIT_BACKOFF"])
pdf_submit_queue_backoff = int(os.environ["PDF_SUBMIT_QUEUE_BACKOFF"])

statusLog = StatusLog(
    cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name
)
utilities = Utilities(
    azure_blob_storage_account,
    azure_blob_drop_storage_container,
    azure_blob_content_storage_container,
    azure_blob_storage_key,
)
FUNCTION_NAME = "FileFormRecSubmissionPDF"
FR_MODEL = "prebuilt-layout"


def main(msg: func.QueueMessage) -> None:
    '''This function is triggered by a message in the pdf-submit-queue.
    It will submit the PDF to Form Recognizer for processing. If the submission
    is throttled, it will requeue the message with a backoff. If the submission
    is successful, it will queue the message to the pdf-polling-queue for polling.'''
    message_body = msg.get_body().decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    try:
        logging.info(
            "Python queue trigger function processed a queue item: %s",
            msg.get_body().decode("utf-8"),
        )

        # Receive message from the queue
        queued_count = message_json["submit_queued_count"]
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Received message from pdf-submit-queue ",
            StatusClassification.DEBUG,
            State.PROCESSING,
        )
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Submitting to Form Recognizer",
            StatusClassification.INFO,
        )
        
        # construct blob url
        blob_path_plus_sas = utilities.get_blob_and_sas(blob_path)
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - SAS token generated",
            StatusClassification.DEBUG,
        )

        # Construct and submmit the message to FR
        headers = {
            "Content-Type": "application/json",
            "Ocp-Apim-Subscription-Key": FR_key,
        }

        params = {"api-version": api_version}

        body = {"urlSource": blob_path_plus_sas}
        url = f"{endpoint}formrecognizer/documentModels/{FR_MODEL}:analyze"

        logging.info(f"Submitting to FR with url: {url}")

        # Send the HTTP POST request with headers, query parameters, and request body
        response = requests.post(url, headers=headers, params=params, json=body)

        # Check if the request was successful (status code 200)
        if response.status_code == 202:
            # Successfully submitted
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - PDF submitted to FR successfully",
                StatusClassification.DEBUG,
            )
            result_id = response.headers.get("apim-request-id")
            message_json["FR_resultId"] = result_id
            message_json["polling_queue_count"] = 1
            queue_client = QueueClient.from_connection_string(
                azure_blob_connection_string,
                queue_name=pdf_polling_queue,
                message_encode_policy=TextBase64EncodePolicy(),
            )
            message_json_str = json.dumps(message_json)
            queue_client.send_message(
                message_json_str, visibility_timeout=poll_queue_submit_backoff
            )
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - message sent to pdf-polling-queue. Visible in {poll_queue_submit_backoff} seconds. FR Result ID is {result_id}",
                StatusClassification.DEBUG,
                State.QUEUED,
            )

        elif response.status_code == 429:
            # throttled, so requeue with random backoff seconds to mitigate throttling,
            # unless it has hit the max tries
            if queued_count < max_submit_requeue_count:
                max_seconds = pdf_submit_queue_backoff * (queued_count**2)
                backoff = random.randint(
                    pdf_submit_queue_backoff * queued_count, max_seconds
                )
                queued_count += 1
                message_json["queued_count"] = queued_count
                statusLog.upsert_document(
                    blob_path,
                    f"{FUNCTION_NAME} - Throttled on PDF submission to FR, requeuing. Back off of {backoff} seconds",
                    StatusClassification.DEBUG,
                )
                queue_client = QueueClient.from_connection_string(
                    azure_blob_connection_string,
                    queue_name=pdf_submit_queue,
                    message_encode_policy=TextBase64EncodePolicy(),
                )
                message_json_str = json.dumps(message_json)
                queue_client.send_message(message_json_str, visibility_timeout=backoff)
                statusLog.upsert_document(
                    blob_path,
                    f"{FUNCTION_NAME} - message sent to pdf-submit-queue. Visible in {backoff} seconds.",
                    StatusClassification.DEBUG,
                    State.QUEUED,
                )
            else:
                statusLog.upsert_document(
                    blob_path,
                    f"{FUNCTION_NAME} - maximum submissions to FR reached",
                    StatusClassification.ERROR,
                    State.ERROR,
                )

        else:
            # general error occurred
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - Error on PDF submission to FR - {response.status_code} - {response.reason}",
                StatusClassification.ERROR,
                State.ERROR,
            )

    except Exception as error:
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - An error occurred - {str(error)}",
            StatusClassification.ERROR,
            State.ERROR,
        )
