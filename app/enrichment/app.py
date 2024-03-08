# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import os
import threading
import time
import re
from datetime import datetime
from typing import List
import base64
import requests
import random
from urllib.parse import unquote
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from data_model import (EmbeddingResponse, ModelInfo, ModelListResponse,
                        StatusResponse)
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from fastapi_utils.tasks import repeat_every
from model_handling import load_models
import openai
from tenacity import retry, wait_random_exponential, stop_after_attempt
from sentence_transformers import SentenceTransformer
from shared_code.utilities_helper import UtilitiesHelper
from shared_code.status_log import State, StatusClassification, StatusLog

# === ENV Setup ===

ENV = {
    "AZURE_BLOB_STORAGE_KEY": None,
    "EMBEDDINGS_QUEUE": None,
    "LOG_LEVEL": "DEBUG", # Will be overwritten by LOG_LEVEL in Environment
    "DEQUEUE_MESSAGE_BATCH_SIZE": 1,
    "AZURE_BLOB_STORAGE_ACCOUNT": None,
    "AZURE_BLOB_STORAGE_CONTAINER": None,
    "AZURE_BLOB_STORAGE_ENDPOINT": None,
    "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER": None,
    "COSMOSDB_URL": None,
    "COSMOSDB_KEY": None,
    "COSMOSDB_LOG_DATABASE_NAME": None,
    "COSMOSDB_LOG_CONTAINER_NAME": None,
    "MAX_EMBEDDING_REQUEUE_COUNT": 5,
    "EMBEDDING_REQUEUE_BACKOFF": 60,
    "AZURE_OPENAI_SERVICE": None,
    "AZURE_OPENAI_SERVICE_KEY": None,
    "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME": None,
    "AZURE_SEARCH_INDEX": None,
    "AZURE_SEARCH_SERVICE_KEY": None,
    "AZURE_SEARCH_SERVICE": None,
    "BLOB_CONNECTION_STRING": None,
    "TARGET_EMBEDDINGS_MODEL": None,
    "EMBEDDING_VECTOR_SIZE": None,
    "AZURE_SEARCH_SERVICE_ENDPOINT": None,
    "AZURE_BLOB_STORAGE_ENDPOINT": None,
    "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER": None
}

for key, value in ENV.items():
    new_value = os.getenv(key)
    if new_value is not None:
        ENV[key] = new_value
    elif value is None:
        raise ValueError(f"Environment variable {key} not set")
    
search_creds = AzureKeyCredential(ENV["AZURE_SEARCH_SERVICE_KEY"])
    
openai.api_base = "https://" + ENV["AZURE_OPENAI_SERVICE"] + ".openai.azure.com/"
openai.api_type = "azure"
openai.api_key = ENV["AZURE_OPENAI_SERVICE_KEY"]
openai.api_version = "2023-06-01-preview"

class AzOAIEmbedding(object):
    """A wrapper for a Azure OpenAI Embedding model"""
    def __init__(self, deployment_name) -> None:
        self.deployment_name = deployment_name
    
    @retry(wait=wait_random_exponential(multiplier=1, max=10), stop=stop_after_attempt(5))
    def encode(self, texts):
        """Embeds a list of texts using a given model"""
        response = openai.Embedding.create(
            engine=self.deployment_name,
            input=texts
        )
        return response

class STModel(object):
    """A wrapper for a sentence-transformers model"""
    def __init__(self, deployment_name) -> None:
        self.deployment_name = deployment_name
        
    @retry(wait=wait_random_exponential(multiplier=1, max=10), stop=stop_after_attempt(5))
    def encode(self, texts) -> None:
        """Embeds a list of texts using a given model"""
        model = SentenceTransformer(self.deployment_name)
        response = model.encode(texts)
        return response
    
# === Get Logger ===

log = logging.getLogger("uvicorn")
log.setLevel(ENV["LOG_LEVEL"])
log.info("Starting up")

# === Azure Setup ===

utilities_helper = UtilitiesHelper(
    azure_blob_storage_account=ENV["AZURE_BLOB_STORAGE_ACCOUNT"],
    azure_blob_storage_endpoint=ENV["AZURE_BLOB_STORAGE_ENDPOINT"],
    azure_blob_storage_key=ENV["AZURE_BLOB_STORAGE_KEY"],
)

statusLog = StatusLog(ENV["COSMOSDB_URL"], ENV["COSMOSDB_KEY"], ENV["COSMOSDB_LOG_DATABASE_NAME"], ENV["COSMOSDB_LOG_CONTAINER_NAME"])
# === API Setup ===

start_time = datetime.now()

IS_READY = False

#download models
log.debug("Loading embedding models...")
models, model_info = load_models()

# Add Azure OpenAI Embedding & additional Model
models["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"]] = AzOAIEmbedding(
    ENV["AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"])

model_info["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"]] = {
    "model": "azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"],
    "vector_size": 1536,
    # Source: https://platform.openai.com/docs/guides/embeddings/what-are-embeddings
}

log.debug("Models loaded")
IS_READY = True

# Create API
app = FastAPI(
    title="Text Embedding Service",
    description="A simple API and Queue Polling service that uses sentence-transformers to embed text",
    version="0.1.0",
    openapi_tags=[
        {"name": "models", "description": "Get information about the available models"},
        {"name": "health", "description": "Health check"},
    ],
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# === API Routes ===
@app.get("/", include_in_schema=False, response_class=RedirectResponse)
def root():
    return RedirectResponse(url="/docs")

@app.get("/health", response_model=StatusResponse, tags=["health"])
def health():
    """Returns the health of the API

    Returns:
        StatusResponse: The health of the API
    """

    uptime = datetime.now() - start_time
    uptime_seconds = uptime.total_seconds()

    output = {"status": None, "uptime_seconds": uptime_seconds, "version": app.version}

    if IS_READY:
        output["status"] = "ready"
    else:
        output["status"] = "loading"

    return output


# Models and Embeddings
@app.get("/models", response_model=ModelListResponse, tags=["models"])
def get_models():
    """Returns a list of available models

    Returns:
        ModelListResponse: A list of available models
    """
    return {"models": list(model_info.values())}


@app.get("/models/{model}", response_model=ModelInfo, tags=["models"])
def get_model(model: str):
    """Returns information about a given model

    Args:
        model (str): The name of the model

    Returns:
        ModelInfo: Information about the model
    """

    if model not in models:
        return {"message": f"Model {model} not found"}
    return model_info[model]


@app.post("/models/{model}/embed", response_model=EmbeddingResponse, tags=["models"])
def embed_texts(model: str, texts: List[str]):
    """Embeds a list of texts using a given model
    Args:
        model (str): The name of the model
        texts (List[str]): A list of texts

    Returns:
        EmbeddingResponse: The embeddings of the texts
    """

    output = {}
    if model not in models:
        return {"message": f"Model {model} not found"}

    model_obj = models[model]
    try:
        if model.startswith("azure-openai_"):
            embeddings = model_obj.encode(texts)
            embeddings = embeddings['data'][0]['embedding']
        else:
            embeddings = model_obj.encode(texts)
            embeddings = embeddings.tolist()[0]

        output = {
            "model": model,
            "model_info": model_info[model],
            "data": embeddings
        }
    
    except Exception as error:
        logging.error(f"Failed to embed: {str(error)}")
        raise HTTPException(status_code=500, detail=f"Failed to embed: {str(error)}") from error

    return output



def index_sections(chunks):
    """ Pushes a batch of content to the search index
    """    
    search_client = SearchClient(endpoint=ENV["AZURE_SEARCH_SERVICE_ENDPOINT"],
                                    index_name=ENV["AZURE_SEARCH_INDEX"],
                                    credential=search_creds)    

    results = search_client.upload_documents(documents=chunks)
    succeeded = sum([1 for r in results if r.succeeded])
    log.debug(f"\tIndexed {len(results)} chunks, {succeeded} succeeded")

def get_tags_and_upload_to_cosmos(blob_service_client, blob_path):
    """ Gets the tags from the blob metadata and uploads them to cosmos db"""
    file_name, file_extension, file_directory = utilities_helper.get_filename_and_extension(blob_path)
    path = file_directory + file_name + file_extension
    blob_client = blob_service_client.get_blob_client(blob=path)
    blob_properties = blob_client.get_blob_properties()
    tags = blob_properties.metadata.get("tags")
    if tags is not None:
        if isinstance(tags, str):
            tags_list = [unquote(tag.strip()) for tag in tags.split(",")]
        else:
            tags_list = [unquote(tag.strip()) for tag in tags]
    else:
        tags_list = []
    # Write the tags to cosmos db
    statusLog.update_document_tags(blob_path, tags_list)
    return tags_list

@app.on_event("startup") 
def startup_event():
    poll_thread = threading.Thread(target=poll_queue_thread)
    poll_thread.daemon = True
    poll_thread.start()

def poll_queue_thread():
    while True:
        poll_queue()
        time.sleep(5)     
        
def poll_queue() -> None:
    """Polls the queue for messages and embeds them"""
    
    if IS_READY == False:
        log.debug("Skipping poll_queue call, models not yet loaded")
        return
    
    queue_client = QueueClient.from_connection_string(
        conn_str=ENV["BLOB_CONNECTION_STRING"], queue_name=ENV["EMBEDDINGS_QUEUE"]
    )

    log.debug("Polling embeddings queue for messages...")
    response = queue_client.receive_messages(max_messages=int(ENV["DEQUEUE_MESSAGE_BATCH_SIZE"]))
    messages = [x for x in response]

    if not messages:
        log.debug("No messages to process. Waiting for a couple of minutes...")
        time.sleep(120)  # Sleep for 2 minutes
        return

    target_embeddings_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', ENV["TARGET_EMBEDDINGS_MODEL"])

    # Remove from queue to prevent duplicate processing from any additional instances
    for message in messages:
        queue_client.delete_message(message)
    
    for message in messages:       
        message_b64 = message.content
        message_json = json.loads(base64.b64decode(message_b64))
        blob_path = message_json["blob_name"]
        
        # write tags to cosmos db once per file/message
        blob_service_client = BlobServiceClient.from_connection_string(ENV["BLOB_CONNECTION_STRING"])
        upload_container_client = blob_service_client.get_container_client(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        tag_list = get_tags_and_upload_to_cosmos(upload_container_client, blob_path)

        try:  
            statusLog.upsert_document(blob_path, f'Embeddings process started with model {target_embeddings_model}', StatusClassification.INFO, State.PROCESSING)
        
            file_name, file_extension, file_directory  = utilities_helper.get_filename_and_extension(blob_path)
            chunk_folder_path = file_directory + file_name + file_extension
            container_client = blob_service_client.get_container_client(ENV["AZURE_BLOB_STORAGE_CONTAINER"])
            index_chunks = []

            # Iterate over the chunks in the container
            chunk_list = container_client.list_blobs(name_starts_with=chunk_folder_path)
            chunks = list(chunk_list)
            i = 0
            
            for chunk in chunks:
                statusLog.update_document_state( blob_path, f"Indexing {i+1}/{len(chunks)}", State.INDEXING)
                # statusLog.update_document_state( blob_path, f"Indexing {i+1}/{len(chunks)}", State.PROCESSING
                # open the file and extract the content
                blob_path_plus_sas = utilities_helper.get_blob_and_sas(
                    ENV["AZURE_BLOB_STORAGE_CONTAINER"] + '/' + chunk.name)
                response = requests.get(blob_path_plus_sas)
                response.raise_for_status()
                chunk_dict = json.loads(response.text)

                # create the json to be indexed
                try:
                    text = (
                        chunk_dict["translated_title"] + " \n " +
                        chunk_dict["translated_subtitle"] + " \n " +
                        chunk_dict["translated_section"] + " \n " +
                        chunk_dict["translated_content"]
                    )
                except KeyError:
                    text = (
                        chunk_dict["title"] + " \n " +
                        chunk_dict["subtitle"] + " \n " +
                        chunk_dict["section"] + " \n " +
                        chunk_dict["content"]
                    )

                try:
                    # try first to read the embedding from the chunk, in case it was already created
                    embedding_data = chunk_dict['contentVector']
                except KeyError:      
                    # create embedding
                    embedding = embed_texts(target_embeddings_model, [text])
                    embedding_data = embedding['data']      
                    
                # ****************************************************************************************************************************
                # this only needs to be done once per file
                # tag_list = get_tags_and_upload_to_cosmos(blob_service_client, chunk_dict["file_name"])
                # ****************************************************************************************************************************

                # Prepare the index schema based representation of the chunk with the embedding
                index_chunk = {}
                index_chunk['id'] = statusLog.encode_document_id(chunk.name)
                index_chunk['processed_datetime'] = f"{chunk_dict['processed_datetime']}+00:00"
                index_chunk['file_name'] = chunk_dict["file_name"]
                index_chunk['file_uri'] = chunk_dict["file_uri"]
                index_chunk['folder'] = file_directory[:-1]
                index_chunk['tags'] = tag_list
                index_chunk['chunk_file'] = chunk.name
                index_chunk['file_class'] = chunk_dict["file_class"]
                index_chunk['title'] = chunk_dict["title"]
                index_chunk['pages'] = chunk_dict["pages"]
                index_chunk['translated_title'] = chunk_dict["translated_title"]
                index_chunk['content'] = text
                index_chunk['contentVector'] = embedding_data
                index_chunk['entities'] = chunk_dict["entities"]
                index_chunk['key_phrases'] = chunk_dict["key_phrases"]
                index_chunks.append(index_chunk)

                # write the updated chunk, with embedding to storage in case of failure
                chunk_dict['contentVector'] = embedding_data
                json_str = json.dumps(chunk_dict, indent=2, ensure_ascii=False)
                block_blob_client = blob_service_client.get_blob_client(container=ENV["AZURE_BLOB_STORAGE_CONTAINER"], blob=chunk.name)
                block_blob_client.upload_blob(json_str, overwrite=True)
                i += 1
                
                # push batch of content to index, rather than each individual chunk
                if i % 200 == 0:
                    index_sections(index_chunks)
                    index_chunks = []

            # push remainder chunks content to index
            if len(index_chunks) > 0:
                index_sections(index_chunks)

            statusLog.upsert_document(blob_path,
                                      'Embeddings process complete',
                                      StatusClassification.INFO, State.COMPLETE)

        except Exception as error:
            # Dequeue message and update the embeddings queued count to limit the max retries
            try:
                requeue_count = message_json['embeddings_queued_count']
            except KeyError:
                requeue_count = 0
            requeue_count += 1

            if requeue_count <= int(ENV["MAX_EMBEDDING_REQUEUE_COUNT"]):
                message_json['embeddings_queued_count'] = requeue_count
                # Requeue with a random backoff within limits
                queue_client = QueueClient.from_connection_string(
                    ENV["BLOB_CONNECTION_STRING"], 
                    ENV["EMBEDDINGS_QUEUE"], 
                    message_encode_policy=TextBase64EncodePolicy())
                message_string = json.dumps(message_json)
                max_seconds = int(ENV["EMBEDDING_REQUEUE_BACKOFF"]) * (requeue_count**2)
                backoff = random.randint(
                    int(ENV["EMBEDDING_REQUEUE_BACKOFF"]) * requeue_count, max_seconds)                
                queue_client.send_message(message_string, visibility_timeout=backoff)
                statusLog.upsert_document(blob_path, f'Message requeued to embeddings queue, attempt {str(requeue_count)}. Visible in {str(backoff)} seconds. Error: {str(error)}.',
                                          StatusClassification.ERROR,
                                          State.QUEUED, additional_info={"Queue_Item": message_string })
            else:
                # max retries has been reached
                statusLog.upsert_document(
                    blob_path,
                    f"An error occurred, max requeue limit was reached. Error description: {str(error)}",
                    StatusClassification.ERROR,
                    State.ERROR,
                )

        statusLog.save_document(blob_path)


