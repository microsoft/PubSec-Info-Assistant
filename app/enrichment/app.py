# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import os
from datetime import datetime
from typing import List
import base64
import requests
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from data_model import (EmbeddingResponse, ModelInfo, ModelListResponse,
                        StatusResponse)
from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi_utils.tasks import repeat_every
from model_handling import load_models
import openai
from tenacity import retry, wait_random_exponential, stop_after_attempt
from sentence_transformers import SentenceTransformer
from utilities_helper import UtilitiesHelper
from shared_code.status_log import State, StatusClassification, StatusLog

# === ENV Setup ===

ENV = {
    "AZURE_BLOB_STORAGE_KEY": None,
    "EMBEDDINGS_QUEUE": None,
    "LOG_LEVEL": "DEBUG", # Will be overwritten by LOG_LEVEL in Environment
    "DEQUEUE_MESSAGE_BATCH_SIZE": 5,
    "AZURE_BLOB_STORAGE_ACCOUNT": None,
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME": None,
    "AZURE_BLOB_STORAGE_CONTAINER": None,
    "COSMOSDB_URL": None,
    "COSMOSDB_KEY": None,
    "COSMOSDB_DATABASE_NAME": None,
    "COSMOSDB_CONTAINER_NAME": None,
    "MAX_EMBEDDING_REQUEUE_COUNT": 5,
    "AZURE_OPENAI_SERVICE": None,
    "AZURE_OPENAI_SERVICE_KEY": None,
    "AZURE_OPENAI_EMBEDDING_MODEL": None,
    "AZURE_SEARCH_INDEX": None,
    "AZURE_SEARCH_SERVICE_KEY": None,
    "AZURE_SEARCH_SERVICE": None,
    "BLOB_CONNECTION_STRING": None,
    "AZURE_BLOB_STORAGE_CONTAINER": None,
    "TARGET_EMBEDDINGS_MODEL": None,
    "EMBEDDING_VECTOR_SIZE": None,
    "AZURE_SEARCH_SERVICE_ENDPOINT": None
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

log.debug("Setting up Azure Storage Queue Client...")
queue_client = QueueClient.from_connection_string(
    conn_str=ENV["BLOB_CONNECTION_STRING"], queue_name=ENV["EMBEDDINGS_QUEUE"]
)
log.debug("Azure Storage Queue Client setup")
statusLog = StatusLog(ENV["COSMOSDB_URL"], ENV["COSMOSDB_KEY"], ENV["COSMOSDB_DATABASE_NAME"], ENV["COSMOSDB_CONTAINER_NAME"])

# === API Setup ===

start_time = datetime.now()

IS_READY = False
log.debug("Loading embedding models...")
models, model_info = load_models()

# Add Azure OpenAI Embedding & additional Model
models["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"]] = AzOAIEmbedding(
    ENV["AZURE_OPENAI_EMBEDDING_MODEL"])
models[ENV["TARGET_EMBEDDINGS_MODEL"]] = STModel(
    ENV["TARGET_EMBEDDINGS_MODEL"])

model_info["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"]] = {
    "model": "azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"],
    "vector_size": 1536,
    # Source: https://platform.openai.com/docs/guides/embeddings/what-are-embeddings
}
model_info[ENV["TARGET_EMBEDDINGS_MODEL"]] = {
    "model": ENV["TARGET_EMBEDDINGS_MODEL"],
    "vector_size": ENV["EMBEDDING_VECTOR_SIZE"],
    # https://huggingface.co/sentence-transformers/all-mpnet-base-v2
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

    if model not in models:
        return {"message": f"Model {model} not found"}

    model_obj = models[model]

    if model.startswith("azure-openai_"):
        embeddings = model_obj.encode(texts)
        embeddings = embeddings['data'][0]['embedding']
    else:
        embeddings = model_obj.encode(texts)
        embeddings = embeddings[0]
        embeddings = embeddings.tolist()
        
    output = {
        "model": model,
        "model_info": model_info[model],
        "data": embeddings
    }

    return output



def index_sections(chunks):
    """ Pushes a batch of content to the search index
    """    
    search_client = SearchClient(endpoint=ENV["AZURE_SEARCH_SERVICE_ENDPOINT"],
                                    index_name=ENV["AZURE_SEARCH_INDEX"],
                                    credential=search_creds)    
    i = 0
    batch = []
    for c in chunks:
        batch.append(c)
        i += 1
        if i % 1000 == 0:
            results = search_client.upload_documents(documents=batch)
            succeeded = sum([1 for r in results if r.succeeded])
            logging.debug(f"\tIndexed {len(results)} chunks, {succeeded} succeeded")
            batch = []

    if len(batch) > 0:
        results = search_client.upload_documents(documents=batch)
        succeeded = sum([1 for r in results if r.succeeded])
        logging.debug(f"\tIndexed {len(results)} chunks, {succeeded} succeeded")

        
@app.on_event("startup") 
@repeat_every(seconds=5, logger=log, raise_exceptions=True)
def poll_queue() -> None:
    """Polls the queue for messages and embeds them"""
    
    if IS_READY == False:
        logging.debug("Skipping poll_queue call, models not yet loaded")
        return

    log.debug("Polling queue for messages...")
    response = queue_client.receive_messages(max_messages=1)
    messages = [x for x in response]
    log.debug(f"Received {len(messages)} messages")

    
    for message in messages:        
        logging.debug(f"Received message {message.id}")
        message_b64 = message.content
        message_json = json.loads(base64.b64decode(message_b64))
        blob_path = message_json["blob_name"]
        statusLog.upsert_document(blob_path, f'Embeddings process started with model ${ENV["TARGET_EMBEDDINGS_MODEL"]}', StatusClassification.INFO, State.PROCESSING)
        
        try:          
            file_name, file_extension, file_directory  = utilities.get_filename_and_extension(blob_path)
            chunk_folder_path = file_directory + file_name + file_extension
            blob_service_client = BlobServiceClient.from_connection_string(ENV["BLOB_CONNECTION_STRING"])
            container_client = blob_service_client.get_container_client(ENV["AZURE_BLOB_STORAGE_CONTAINER"])
            index_chunks = []
            
            # Iterate over the chunks in the container
            chunk_list = container_client.list_blobs(name_starts_with=chunk_folder_path)
            for i, chunk in enumerate(chunk_list):
                # open the file and extract the content
                blob_path_plus_sas = utilities.get_blob_and_sas(ENV["AZURE_BLOB_STORAGE_CONTAINER"] + '/' + chunk.name)
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
                    
                # create embedding
                embedding = embed_texts(ENV["TARGET_EMBEDDINGS_MODEL"], text)   
                embedding_data = embedding['data']                   
                
                index_chunk = {}
                index_chunk['id'] = statusLog.encode_document_id(chunk_dict['file_uri'])
                index_chunk['processed_datetime'] = f"{chunk_dict['processed_datetime']}+00:00"
                index_chunk['file_name'] = chunk_dict["file_name"]
                index_chunk['file_uri'] = chunk_dict["file_uri"]
                index_chunk['title'] = chunk_dict["title"]
                index_chunk['translated_title'] = chunk_dict["translated_title"]         
                index_chunk['content'] = text
                index_chunk['contentVector'] = embedding_data    
                index_chunks.append(index_chunk)
                
            # push chunk content to index
            index_sections(index_chunks)

            # delete message once complete, in case of failure
            queue_client.delete_message(message)      
            statusLog.upsert_document(blob_path, 'Embeddings process complete', StatusClassification.INFO, State.COMPLETE)
        
        except Exception as error:
            statusLog.upsert_document(
                blob_path,
                f"An error occurred - {str(error)}",
                StatusClassification.ERROR,
                State.ERROR,
            )
        
        statusLog.save_document()
