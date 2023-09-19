# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import os
from datetime import datetime
from typing import List
from uuid import uuid4
import base64

from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from data_model import (EmbeddingResponse, ModelInfo, ModelListResponse,
                        StatusResponse)
from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi_utils.tasks import repeat_every
from model_handling import load_models
import openai
from tenacity import retry, wait_random_exponential, stop_after_attempt

from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities

# === ENV Setup ===

ENV = {
    "BLOB_STORAGE_ACCOUNT_KEY": None,
    "EMBEDDING_QUEUE_NAME": None,
    "LOG_LEVEL": "DEBUG", # Will be overwritten by LOG_LEVEL in Environment
    "DEQUEUE_MESSAGE_BATCH_SIZE": 5,
    "BLOB_STORAGE_ACCOUNT": None,
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME": None,
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME": None,
    "COSMOSDB_URL": None,
    "COSMOSDB_KEY": None,
    "COSMOSDB_DATABASE_NAME": None,
    "COSMOSDB_CONTAINER_NAME": None,
    "MAX_EMBEDDING_REQUEUE_COUNT": 5,
    "AZURE_OPENAI_SERVICE": None,
    "AZURE_OPENAI_SERVICE_KEY": None,
    "AZURE_OPENAI_EMBEDDING_MODEL": None,
    "AZURE_SEARCH_INDEX": None,
    "AZURE_SEARCH_KEY": None,
    "AZURE_SEARCH_SERVICE": None
}

for key, value in ENV.items():
    new_value = os.getenv(key)
    if new_value is not None:
        ENV[key] = new_value
    elif value is None:
        raise ValueError(f"Environment variable {key} not set")


openai.api_base = "https://" + ENV["AZURE_OPENAI_SERVICE"] + ".openai.azure.com/"
openai.api_type = "azure"
openai.api_key = ENV["AZURE_OPENAI_SERVICE_KEY"]
openai.api_version = "2023-06-01-preview"

class AzOAIEmbedding(object):
    def __init__(self, deployment_name) -> None:
        self.deployment_name = deployment_name
    
    @retry(wait=wait_random_exponential(multiplier=1, max=10), stop=stop_after_attempt(5))
    def encode(self, texts):
        response = openai.Embedding.create(
            engine=self.deployment_name,
            documents=texts
        )
        return response

# === Get Logger ===

log = logging.getLogger("uvicorn")
log.setLevel(ENV["LOG_LEVEL"])
log.info("Starting up")

# === Azure Setup ===

utilities = Utilities(
    azure_blob_storage_account=ENV["BLOB_STORAGE_ACCOUNT"],
    azure_blob_drop_storage_container=ENV["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"],
    azure_blob_content_storage_container=ENV["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"],
    azure_blob_storage_key=ENV["BLOB_STORAGE_ACCOUNT_KEY"],
)

log.debug("Setting up Azure Storage Queue Client...")
queue_client = QueueClient.from_connection_string(
    conn_str=ENV["AZURE_STORAGE_CONNECTION_STRING"], queue_name=ENV["EMBEDDING_QUEUE_NAME"]
)
log.debug("Azure Storage Queue Client setup")

# === API Setup ===

start_time = datetime.now()

IS_READY = False
log.debug("Loading embedding models...")
models, model_info = load_models()

# Add Azure OpenAI Embedding Model
models["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"]] = AzOAIEmbedding(ENV["AZURE_OPENAI_EMBEDDING_MODEL"])
model_info["azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"]] = {
    "model": "azure-openai_" + ENV["AZURE_OPENAI_EMBEDDING_MODEL"],
    "max_seq_length": 8191, # Source: https://platform.openai.com/docs/guides/embeddings/what-are-embeddings
    "vector_size": 1536,
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
        output = model_obj.encode(texts)
    else:
        embeddings = model_obj.encode(texts)

        reformatted_embeddings = []

        for i, embedding in enumerate(embeddings):
            new_embedding = {
                "object": "embedding",
                "index": i,
                "embedding": list(embedding),
            }
            reformatted_embeddings.append(new_embedding)

        output = {
            "object": "list",
            "data": reformatted_embeddings,
            "embedding_id": str(uuid4()),
            "model": model,
            "model_info": model_info[model],
        }

    return output

@app.on_event("startup") 
@repeat_every(seconds=5, logger=log, raise_exceptions=True)
def poll_queue() -> None:
    """Polls the queue for messages and embeds them"""

    if IS_READY == False:
        logging.debug("Skipping poll_queue call, models not yet loaded")
        return

    # log.debug("Polling queue for messages...")
    response = queue_client.receive_messages(max_messages=5)
    messages = [x for x in response]
    # log.debug(f"Received {len(messages)} messages")

    for message in messages:
        logging.debug(f"Received message {message.id}")
        message_b64 = message.content
        message_dict = json.loads(base64.b64decode(message_b64))

        model_to_use = message_dict["model"]
        texts = [message_dict["text"]]

        # Embed 
        log.debug(f"Embedding message {message.id}")
        output = embed_texts(model_to_use, texts)
        log.debug(f"Embedded message {message.id}")

        queue_client.delete_message(message)
