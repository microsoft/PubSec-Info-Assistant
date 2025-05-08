# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from io import StringIO
from typing import Optional
from datetime import datetime
import asyncio
import logging
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
import uvicorn
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'functions')))
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'shared_code')))
import json
import urllib.parse
import pandas as pd
import pydantic
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, File, HTTPException, Request, UploadFile, Form
from fastapi.responses import RedirectResponse, StreamingResponse
from dotenv import load_dotenv
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, ContentSettings
from azure.cosmos import CosmosClient
from shared_code.status_log import State, StatusClassification, StatusLog
import uuid

# Load environment variables from backend.env
env_file_path = os.path.join(os.path.dirname(__file__), "backend.env")
load_dotenv(env_file_path)

# === ENV Setup ===
ENV = {
    "AZURE_BLOB_STORAGE_ACCOUNT": os.getenv("AZURE_BLOB_STORAGE_ACCOUNT"),
    "AZURE_BLOB_STORAGE_ENDPOINT": os.getenv("AZURE_BLOB_STORAGE_ENDPOINT"),
    "AZURE_BLOB_STORAGE_CONTAINER": os.getenv("AZURE_BLOB_STORAGE_CONTAINER"),
    "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER": os.getenv("AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"),
    "COSMOSDB_URL": os.getenv("COSMOSDB_URL"),
    "COSMOSDB_LOG_DATABASE_NAME": os.getenv("COSMOSDB_LOG_DATABASE_NAME"),
    "COSMOSDB_LOG_CONTAINER_NAME": os.getenv("COSMOSDB_LOG_CONTAINER_NAME"),
    "CHAT_WARNING_BANNER_TEXT": os.getenv("CHAT_WARNING_BANNER_TEXT"),
    "APPLICATION_TITLE": os.getenv("APPLICATION_TITLE"),
    "MAX_CSV_FILE_SIZE": os.getenv("MAX_CSV_FILE_SIZE", "7"),
    "LOCAL_DEBUG": os.getenv("LOCAL_DEBUG", "false").lower() == "true",
}

# Log loaded environment variables for debugging
log = logging.getLogger("uvicorn")
log.setLevel(logging.DEBUG)
log.info(f"Loaded environment variables from {env_file_path}")

# Use DefaultAzureCredential for local debugging, ManagedIdentityCredential for Azure
if ENV["LOCAL_DEBUG"]:
    azure_credential = DefaultAzureCredential()
else:
    azure_credential = ManagedIdentityCredential()

# Setup StatusLog to allow access to CosmosDB for logging
log.info(f"StatusLog module path: {StatusLog.__module__}")
statusLog = StatusLog(
    ENV["COSMOSDB_URL"],
    azure_credential,
    ENV["COSMOSDB_LOG_DATABASE_NAME"],
    ENV["COSMOSDB_LOG_CONTAINER_NAME"]
)

# Set up Blob Storage client
blob_client = BlobServiceClient(
    account_url=ENV["AZURE_BLOB_STORAGE_ENDPOINT"],
    credential=azure_credential,
)
blob_container = blob_client.get_container_client(ENV["AZURE_BLOB_STORAGE_CONTAINER"])
blob_upload_container_client = blob_client.get_container_client(
    ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"]
)

# Create API
app = FastAPI(
    title="IA Web API",
    description="A Python API to serve as Backend For the Information Assistant Web App",
    version="0.1.0",
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or set your frontend's URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", include_in_schema=False, response_class=RedirectResponse)
async def root():
    """Redirect to the index.html page"""
    return RedirectResponse(url="/index.html")

@app.get("/health", tags=["health"])
def health():
    """Returns the health of the API"""
    uptime = datetime.now() - start_time
    return {"status": "ready", "uptime_seconds": uptime.total_seconds(), "version": app.version}

@app.post("/getalluploadstatus")
async def get_all_upload_status(request: Request):
    """Get the status and tags of all file uploads in the last N hours."""
    json_body = await request.json()
    timeframe = json_body.get("timeframe")
    state = json_body.get("state")
    folder = json_body.get("folder")
    tag = json_body.get("tag")
    try:
        results = statusLog.read_files_status_by_timeframe(
            timeframe,
            State[state],
            folder,
            tag,
            ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"]
        )
    except Exception as ex:
        log.exception("Exception in /getalluploadstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.post("/getfolders")
async def get_folders():
    """
    Get all folders.
    """
    try:
        blob_container = blob_client.get_container_client(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        folders = []
        blob_list = blob_container.list_blobs()

        for blob in blob_list:
            folder_path = os.path.dirname(blob.name)
            if folder_path and folder_path not in folders:
                folders.append(folder_path)

        return {"folders": folders}
    except Exception as ex:
        log.exception("Exception in /getfolders")
        raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.post("/deleteItems")
async def delete_items(request: Request):
    """Delete a blob."""
    json_body = await request.json()
    full_path = json_body.get("path")
    path = full_path.split("/", 1)[1]
    try:
        blob_container = blob_client.get_container_client(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        blob_container.delete_blob(path)
        statusLog.upsert_document(
            document_path=full_path,
            status='Delete initiated',
            status_classification=StatusClassification.INFO,
            state=State.DELETING,
            fresh_start=False
        )
        statusLog.save_document(document_path=full_path)
    except Exception as ex:
        log.exception("Exception in /deleteItems")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return True

@app.post("/resubmitItems")
async def resubmit_items(request: Request):
    """
    Resubmit a blob.
    """
    try:
        json_body = await request.json()
        path = json_body.get("path")
        if not path:
            raise HTTPException(status_code=400, detail="path is required.")

        # Remove the container prefix
        path = path.split("/", 1)[1]

        blob_container = blob_client.get_container_client(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        blob_data = blob_container.download_blob(path).readall()

        submitted_blob_client = blob_container.get_blob_client(blob=path)
        blob_properties = submitted_blob_client.get_blob_properties()
        metadata = blob_properties.metadata

        # Re-upload the blob with metadata
        blob_container.upload_blob(name=path, data=blob_data, overwrite=True, metadata=metadata)

        # Add the container to the path to avoid adding another document in the status DB
        full_path = ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"] + '/' + path
        statusLog.upsert_document(
            document_path=full_path,
            status='Resubmitted to the processing pipeline',
            status_classification=StatusClassification.INFO,
            state=State.QUEUED,
            fresh_start=False
        )
        statusLog.save_document(document_path=full_path)

        return {"message": "Blob resubmitted successfully."}
    except Exception as ex:
        log.exception("Exception in /resubmitItems")
        raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.post("/logstatus")
async def logstatus(request: Request):
    try:
        json_body = await request.json()
        document_path = json_body.get("document_path")  # Match the frontend's key
        status = json_body.get("status")
        status_classification = StatusClassification[json_body.get("status_classification").upper()]
        state = State[json_body.get("state").upper()]

        # Add validation to ensure required fields are present
        if not document_path:
            raise HTTPException(status_code=400, detail="document_path is required and cannot be null.")
        if not status:
            raise HTTPException(status_code=400, detail="status is required and cannot be null.")

        statusLog.upsert_document(document_path=document_path,
                                  status=status,
                                  status_classification=status_classification,
                                  state=state,
                                  fresh_start=True)
        statusLog.save_document(document_path=document_path)

        return {"message": "Status logged successfully."}
    except Exception as ex:
        log.exception("Exception in /logstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.get("/getApplicationTitle")
async def get_application_title():
    """Get the application title."""
    return {"APPLICATION_TITLE": ENV["APPLICATION_TITLE"]}

@app.get("/getWarningBanner")
async def get_warning_banner():
    """Get the warning banner text."""
    return {"WARNING_BANNER_TEXT": ENV["CHAT_WARNING_BANNER_TEXT"]}

@app.get("/getMaxCSVFileSize")
async def get_max_csv_file_size():
    """Get the max CSV file size."""
    return {"MAX_CSV_FILE_SIZE": ENV["MAX_CSV_FILE_SIZE"]}

@app.get("/getalltags")
async def get_all_tags():
    """Get all tags."""
    log.info("GET /getalltags endpoint was called.")
    return {"tags": ["tag1", "tag2", "tag3"]}

@app.get("/getFeatureFlags")
async def get_feature_flags():
    """Get feature flags."""
    return {"feature_flags": {"feature1": True, "feature2": False}}

@app.post("/file")
async def upload_file(
    file: UploadFile = File(...),
    file_path: str = Form(...),
    tags: str = Form(None)
):
    """
    Upload a file to Azure Blob Storage.
    """
    try:
        if not file_path:
            raise HTTPException(status_code=400, detail="file_path is required.")

        blob_upload_client = blob_upload_container_client.get_blob_client(file_path)

        # Upload the file to Blob Storage
        blob_upload_client.upload_blob(
            file.file,
            overwrite=True,
            content_settings=ContentSettings(content_type=file.content_type),
            metadata={"tags": tags} if tags else None
        )

        return {"message": f"File '{file.filename}' uploaded successfully"}

    except Exception as ex:
        log.exception("Exception in /file")
        raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.post("/gettags")
async def get_tags(request: Request):
    """Get tags."""
    json_body = await request.json()
    return {"tags": ["tag1", "tag2", "tag3"]}

# Dynamically resolve the path to the static directory
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")
else:
    log.warning(f"Static directory '{static_dir}' does not exist. Static files will not be served.")

if __name__ == "__main__":
    log.info("IA WebApp Starting Up...")
    port = int(os.getenv("PORT", 8000))  # default to port 8000
    log.info(f"Starting Uvicorn on port {port}")
    uvicorn.run("app:app", host="0.0.0.0", port=port)
