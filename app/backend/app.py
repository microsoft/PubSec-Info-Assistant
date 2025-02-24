# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from datetime import datetime, timezone, timedelta
import logging
import os
import json
import urllib.parse
from enum import StrEnum
import pydantic
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, File, HTTPException, Request, UploadFile, Form
from fastapi.responses import RedirectResponse, StreamingResponse
import openai
from approaches.comparewebwithwork import CompareWebWithWork
from approaches.compareworkwithweb import CompareWorkWithWeb
from approaches.chatreadretrieveread import ChatReadRetrieveReadApproach
from approaches.chatwebretrieveread import ChatWebRetrieveRead
from approaches.gpt_direct_approach import GPTDirectApproach
from approaches.approach import Approaches
from azure.identity import ManagedIdentityCredential, AzureAuthorityHosts, DefaultAzureCredential, get_bearer_token_provider
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from azure.search.documents import SearchClient
from azure.storage.blob import BlobServiceClient, ContentSettings
from azure.data.tables import TableServiceClient, TableClient
from monitoring import configure_monitoring
from urllib.parse import urlparse, parse_qs
from azure.search.documents.indexes import SearchIndexerClient
import traceback






# === ENV Setup ===

ENV = {
    "AZURE_BLOB_STORAGE_ACCOUNT": None,
    "AZURE_BLOB_STORAGE_ENDPOINT": None,
    "AZURE_BLOB_STORAGE_CONTAINER": "content",
    "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER": "upload",
    "AZURE_SEARCH_SERVICE": "gptkb",
    "AZURE_SEARCH_SERVICE_ENDPOINT": None,
    "AZURE_SEARCH_INDEX": "gptkbindex",
    "AZURE_SEARCH_AUDIENCE": None,
    "TABLE_STORAGE_ACCOUNT_ENDPOINT": None,
    "USE_SEMANTIC_RERANKER": "true",
    "AZURE_OPENAI_SERVICE": "myopenai",
    "AZURE_OPENAI_RESOURCE_GROUP": "",
    "AZURE_OPENAI_ENDPOINT": "",
    "AZURE_OPENAI_AUTHORITY_HOST": "AzureCloud",
    "AZURE_OPENAI_CHATGPT_DEPLOYMENT": "gpt-35-turbo-16k",
    "AZURE_OPENAI_CHATGPT_MODEL_NAME": "",
    "AZURE_OPENAI_CHATGPT_MODEL_VERSION": "",
    "EMBEDDING_DEPLOYMENT_NAME": "",
    "AZURE_OPENAI_EMBEDDINGS_MODEL_NAME": "",
    "AZURE_OPENAI_EMBEDDINGS_VERSION": "",
    "AZURE_SUBSCRIPTION_ID": None,
    "AZURE_ARM_MANAGEMENT_API": "https://management.azure.com",
    "CHAT_WARNING_BANNER_TEXT": "",
    "APPLICATION_TITLE": "Information Assistant, built with Azure OpenAI",
    "KB_FIELDS_CONTENT": "content",
    "KB_FIELDS_PAGENUMBER": "pages",
    "KB_FIELDS_SOURCEFILE": "file_name",
    "KB_FIELDS_CHUNKFILE": "chunk_file",
    "QUERY_TERM_LANGUAGE": "English",
    "TARGET_TRANSLATION_LANGUAGE": "en",
    "AZURE_AI_ENDPOINT": None,
    "AZURE_AI_LOCATION": "",
    "BING_SEARCH_ENDPOINT": "https://api.bing.microsoft.com/",
    "BING_SEARCH_KEY": "",
    "USE_BING_SAFE_SEARCH": "true",
    "USE_WEB_CHAT": "false",
    "USE_UNGROUNDED_CHAT": "false",
    "LOCAL_DEBUG": "false", 
    "AZURE_AI_CREDENTIAL_DOMAIN": "cognitiveservices.azure.com",
    "ENRICHMENT_STATUS_TABLE": "enrichmentstatus"
}

for key, value in ENV.items():
    new_value = os.getenv(key)
    if new_value is not None:
        ENV[key] = new_value
    elif value is None:
        raise ValueError(f"Environment variable {key} not set")

str_to_bool = {'true': True, 'false': False}

class StatusResponse(pydantic.BaseModel):
    """The response model for the health check endpoint"""
    status: str
    uptime_seconds: float
    version: str

class StatusLogClassification(StrEnum):
    """The classification of the status log"""
    INFO = "Info"
    WARNING = "Warning"
    ERROR = "Error"

class StatusLogState(StrEnum):
    """The state of the status log"""
    RESUBMITTED = "Resubmitted"
    DELETED = "Deleted"


start_time = datetime.now()
IS_READY = False
DF_FINAL = None
# Used by the OpenAI SDK
openai.api_type = "azure"
openai.api_base = ENV["AZURE_OPENAI_ENDPOINT"]
if ENV["AZURE_OPENAI_AUTHORITY_HOST"] == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD
openai.api_version = "2024-02-01"
# When debugging in VS Code, use the current user identity to authenticate with Azure OpenAI,
# Cognitive Search and Blob Storage (no secrets needed, just use 'az login' locally)
# Use managed identity when deployed on Azure.
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude
# the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
if ENV["LOCAL_DEBUG"] == "true":
    azure_credential = DefaultAzureCredential(authority=AUTHORITY)
else:
    azure_credential = ManagedIdentityCredential(authority=AUTHORITY)
# Comment these two lines out if using keys, set your API key in the OPENAI_API_KEY
# environment variable instead
openai.api_type = "azure_ad"
token_provider = get_bearer_token_provider(azure_credential,
                                           f'https://{ENV["AZURE_AI_CREDENTIAL_DOMAIN"]}/.default')
openai.azure_ad_token_provider = token_provider
# openai.api_key = ENV["AZURE_OPENAI_SERVICE_KEY"]

# Set up clients for Cognitive Search and Storage
search_client = SearchClient(
    endpoint=ENV["AZURE_SEARCH_SERVICE_ENDPOINT"],
    index_name=ENV["AZURE_SEARCH_INDEX"],
    credential=azure_credential,
    audience=ENV["AZURE_SEARCH_AUDIENCE"]
)



blob_client = BlobServiceClient(
    account_url=ENV["AZURE_BLOB_STORAGE_ENDPOINT"],
    credential=azure_credential,
)
blob_container = blob_client.get_container_client(
    ENV["AZURE_BLOB_STORAGE_CONTAINER"])
blob_upload_container_client = blob_client.get_container_client(
    os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])

UPLOAD_TABLE_NAME = "fileprocessingstatus"

table_service_client = TableServiceClient(
    endpoint=ENV["TABLE_STORAGE_ACCOUNT_ENDPOINT"], credential=azure_credential)

MODEL_NAME = ''
MODEL_VERSION = ''

# Set up OpenAI management client
openai_mgmt_client = CognitiveServicesManagementClient(
    credential=azure_credential,
    subscription_id=ENV["AZURE_SUBSCRIPTION_ID"],
    base_url=ENV["AZURE_ARM_MANAGEMENT_API"],
    credential_scopes=[ENV["AZURE_ARM_MANAGEMENT_API"] + "/.default"])

deployment = openai_mgmt_client.deployments.get(
    resource_group_name=ENV["AZURE_OPENAI_RESOURCE_GROUP"],
    account_name=ENV["AZURE_OPENAI_SERVICE"],
    deployment_name=ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"])

MODEL_NAME = deployment.properties.model.name
MODEL_VERSION = deployment.properties.model.version
if (ENV["EMBEDDING_DEPLOYMENT_NAME"] != ""):
    embedding_deployment = openai_mgmt_client.deployments.get(
        resource_group_name=ENV["AZURE_OPENAI_RESOURCE_GROUP"],
        account_name=ENV["AZURE_OPENAI_SERVICE"],
        deployment_name=ENV["EMBEDDING_DEPLOYMENT_NAME"])

    EMBEDDING_MODEL_NAME = embedding_deployment.properties.model.name
    EMBEDDING_MODEL_VERSION = embedding_deployment.properties.model.version
else:
    EMBEDDING_MODEL_NAME = ""
    EMBEDDING_MODEL_VERSION = ""

chat_approaches = {
    Approaches.ReadRetrieveRead: ChatReadRetrieveReadApproach(
        search_client,
        ENV["AZURE_OPENAI_ENDPOINT"],
        ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        ENV["KB_FIELDS_SOURCEFILE"],
        ENV["KB_FIELDS_CONTENT"],
        ENV["KB_FIELDS_PAGENUMBER"],
        ENV["KB_FIELDS_CHUNKFILE"],
        ENV["AZURE_BLOB_STORAGE_CONTAINER"],
        blob_client,
        ENV["QUERY_TERM_LANGUAGE"],
        MODEL_NAME,
        MODEL_VERSION,
        ENV["EMBEDDING_DEPLOYMENT_NAME"],
        "",
        ENV["TARGET_TRANSLATION_LANGUAGE"],
        ENV["AZURE_AI_ENDPOINT"],
        ENV["AZURE_AI_LOCATION"],
        token_provider,
        str_to_bool.get(
            ENV["USE_SEMANTIC_RERANKER"])
    ),
    Approaches.ChatWebRetrieveRead: ChatWebRetrieveRead(
        MODEL_NAME,
        ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        ENV["TARGET_TRANSLATION_LANGUAGE"],
        ENV["BING_SEARCH_ENDPOINT"],
        ENV["BING_SEARCH_KEY"],
        str_to_bool.get(ENV["USE_BING_SAFE_SEARCH"]),
        ENV["AZURE_OPENAI_ENDPOINT"],
        token_provider
    ),
    Approaches.CompareWorkWithWeb: CompareWorkWithWeb(
        MODEL_NAME,
        ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        ENV["TARGET_TRANSLATION_LANGUAGE"],
        ENV["BING_SEARCH_ENDPOINT"],
        ENV["BING_SEARCH_KEY"],
        str_to_bool.get(ENV["USE_BING_SAFE_SEARCH"]),
        ENV["AZURE_OPENAI_ENDPOINT"],
        token_provider
    ),
    Approaches.CompareWebWithWork: CompareWebWithWork(
        search_client,
        ENV["AZURE_OPENAI_ENDPOINT"],
        ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        ENV["KB_FIELDS_SOURCEFILE"],
        ENV["KB_FIELDS_CONTENT"],
        ENV["KB_FIELDS_PAGENUMBER"],
        ENV["KB_FIELDS_CHUNKFILE"],
        ENV["AZURE_BLOB_STORAGE_CONTAINER"],
        blob_client,
        ENV["QUERY_TERM_LANGUAGE"],
        MODEL_NAME,
        MODEL_VERSION,
        "",
        "",
        ENV["TARGET_TRANSLATION_LANGUAGE"],
        ENV["AZURE_AI_ENDPOINT"],
        ENV["AZURE_AI_LOCATION"],
        token_provider,
        str_to_bool.get(
            ENV["USE_SEMANTIC_RERANKER"])
    ),
    Approaches.GPTDirect: GPTDirectApproach(
        token_provider,
        ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        ENV["QUERY_TERM_LANGUAGE"],
        MODEL_NAME,
        MODEL_VERSION,
        ENV["AZURE_OPENAI_ENDPOINT"]
    )
}

IS_READY = True

# Create API
app = FastAPI(
    title="IA Web API",
    description="A Python API to serve as Backend For the Information Assistant Web App",
    version="0.1.0",
    docs_url="/docs",
)

# Configure monitoring
log, trace, meter = configure_monitoring(app)


@app.get("/", include_in_schema=False, response_class=RedirectResponse)
async def root():
    """Redirect to the index.html page"""
    return RedirectResponse(url="/index.html")


@app.get("/health", response_model=StatusResponse, tags=["health"])
def health():
    """Returns the health of the API

    Returns:
        StatusResponse: The health of the API
    """

    uptime = datetime.now() - start_time
    uptime_seconds = uptime.total_seconds()

    output = {"status": None, "uptime_seconds": uptime_seconds,
              "version": app.version}

    if IS_READY:
        output["status"] = "ready"
    else:
        output["status"] = "loading"

    return output


@app.post("/chat")
async def chat(request: Request):
    """Chat with the bot using a given approach

    Args:
        request (Request): The incoming request object

    Returns:
        dict: The response containing the chat results

    Raises:
        dict: The error response if an exception occurs during the chat
    """
    json_body = await request.json()
    approach = json_body.get("approach")
    try:
        impl = chat_approaches.get(Approaches(int(approach)))
        if not impl:
            return {"error": "unknown approach"}, 400

        if (Approaches(int(approach)) == Approaches.CompareWorkWithWeb or
                Approaches(int(approach)) == Approaches.CompareWebWithWork):
            r = impl.run(json_body.get("history", []),
                         json_body.get("overrides", {}),
                         json_body.get("citation_lookup", {}),
                         json_body.get("thought_chain", {}))
        else:
            r = impl.run(json_body.get("history", []),
                         json_body.get("overrides", {}),
                         {},
                         json_body.get("thought_chain", {}))

        return StreamingResponse(r, media_type="application/x-ndjson")

    except Exception as ex:
        log.error("Error in chat:: %s", ex)
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    

def process_errors_warnings(execution_history, entity, list_to_append, item_type):
    """
    Process errors or warnings and append relevant details to the provided list.

    Parameters:
    - items: List of errors or warnings to process.
    - entity: The entity to compare against.
    - list_to_append: The list to append the processed details to.
    - item_type: The type of item being processed ("error" or "warning").
    """
    for history_item in execution_history:
        items = history_item.errors if item_type == "error" else history_item.warnings
        for item in items:
            parsed_url = urlparse(item.key)
            query_params = parse_qs(parsed_url.path)
            document_key = query_params.get("documentKey", [None])[0]
            if document_key:
                document_key = urllib.parse.unquote(document_key)
                document_path_parts = document_key.split("upload/", 1)[1]
                if len(document_path_parts.split('/')) > 1:
                    folder, file_name = document_path_parts.split('/', 1)
                    folder = "upload/" + folder
                else:
                    file_name = document_path_parts.split('/')[0]
                    folder = "upload"
                if file_name == entity.get("RowKey") and folder == urllib.parse.unquote(entity.get("PartitionKey")):
                    list_to_append.append(item.details + f" skill: {item.name}")


def get_status_set(skillset_entity, status_key, default_message):
    """
    Extract and process the status set from the skillset entity.

    Parameters:
    - skillset_entity: The skillset entity to extract the status from.
    - status_key: The key to extract the status from the entity.
    - default_message: The default message to use if the status set is empty.

    Returns:
    - A set containing the processed status.
    """
    status_set = set(skillset_entity.get(status_key, '').replace('[', '').replace(']', '').replace('"', '').split(','))
    if status_set == {''}:
        status_set = {default_message}
    return status_set

@app.post("/getalluploadstatus")
async def get_all_upload_status(request: Request):
    """
    Get the status and tags of all file uploads in the last N hours.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: The status of all file uploads in the specified timeframe.
    """
    json_body = await request.json()
    try:
        results = []
        timeframe = json_body.get("timeframe", 0)
        state = json_body.get("state", "ALL")
        folder = json_body.get("folder", "")
        tag = json_body.get("tag", "All")
        table_client = table_service_client.get_table_client(table_name=UPLOAD_TABLE_NAME)
        status_start_time = (datetime.now(timezone.utc) - timedelta(hours=timeframe)).isoformat() if timeframe > 0 else None

        indexer_client = SearchIndexerClient(
                    endpoint=ENV["AZURE_SEARCH_SERVICE_ENDPOINT"],
                    credential=azure_credential
                )
        index_errors_warnings = indexer_client.get_indexer_status("indexer")
        skillset_table_client = table_service_client.get_table_client(table_name=ENV["ENRICHMENT_STATUS_TABLE"])


       
        # retrieve tags for each file
        # Initialize an empty list to hold the tags
        if folder == 'Root':
            folder = 'upload'
        entities = list(table_client.list_entities())
        if entities:
            for i, entity in enumerate(entities):
                created_timestamp = entity.get("created_timestamp")
                if created_timestamp:
                    created_timestamp = datetime.fromisoformat(created_timestamp).isoformat(timespec='microseconds')
                
                # Apply filtering
                if status_start_time and created_timestamp and created_timestamp < status_start_time:
                    # Skip entities that were created before the specified timeframe and the api call 
                    continue

                if state != "ALL" and entity.get("state").upper() != state:
                    # Skip entities that do not match the specified state
                    continue

                partition_key_parts = urllib.parse.unquote(entity.get("PartitionKey")).split('/')
                if folder and folder not in partition_key_parts:
                    # Skip entities that do not belong to the specified folder
                    continue

                if tag != "All":
                    entity_tags = set(entity.get("tags", '').split(','))
                    if tag not in entity_tags:
                        # Skip entities that do not have the specified tag
                        continue
                warning_list = []
                error_list = []
                error_warning_status = None

                # Process errors and warnings
                process_errors_warnings(index_errors_warnings.execution_history, entity, error_list, "error")
                process_errors_warnings(index_errors_warnings.execution_history, entity, warning_list, "warning")
                error_list = list(set(error_list))
                warning_list = list(set(warning_list))
                
                document_indexed = False
                try:
                    expected_path = f"{entity.get('PartitionKey')}/{entity.get('RowKey')}"
                    
                except Exception as ex:
                    log.exception("Exception in checking document index status")
                    raise HTTPException(status_code=500, detail=str(ex)) from ex
                if error_list:
                    error_warning_status = "Error"
                

                
                
                statuses = entity.get("status", '').split(',')
                if warning_list:
                    statuses += warning_list
                if error_list:
                    statuses += error_list
                # Set the status to the last object in the status_updates list
                last_status = statuses[-1] if statuses else entity.get("status", '')
                
                result = {
                    "id": i,
                    "file_path": urllib.parse.unquote(entity.get("PartitionKey")),
                    "file_name": entity.get("RowKey"),
                    "state": error_warning_status if error_warning_status else entity.get("state"),
                    "state_description": last_status,
                    "state_timestamp": entity.metadata.get('timestamp').tables_service_value if entity.metadata.get('timestamp').tables_service_value else None,
                    "status": last_status,
                    "tags": entity.get("tags", ''),
                    "status_updates": statuses,
                    "start_timestamp" : created_timestamp if created_timestamp else ''
                }
                results.append(result)

        skillset_entities = list(skillset_table_client.list_entities())
        if skillset_entities:
            for skillset_entity in skillset_entities:
                skillset_status = []
                skillset_filepath = urllib.parse.unquote(skillset_entity.get("filepath"))
                document_path = skillset_filepath.split("upload/", 1)[1]
                ex_status_set = get_status_set(skillset_entity, "ex_status", "extraction did not run or failed")
                split_status_set = get_status_set(skillset_entity, "split_status", "split skill did not run or failed")
                image_enr_status_set = get_status_set(skillset_entity, "image_enr_status", "image enrichment did not run or failed")
                text_enrichment_status_set = get_status_set(skillset_entity, "text_enrichment_status", "text enrichment did not run or failed")
                embedding_status_set = get_status_set(skillset_entity, "embedding_status", "embedding skill did not run or failed")


                # Find differences between sets
                skillset_status_set = ex_status_set.union(split_status_set).union(image_enr_status_set).union(text_enrichment_status_set).union(embedding_status_set)
                
                # Convert set to list and join with commas
                skillset_status = ', '.join(skillset_status_set)
                
                
                skillpath = 'upload/' + document_path
                
                
                # Find the matching result and add the skillset status to the status_updates
                final_e = {}
                for result in results:
                    if result["file_path"] + "/" + result["file_name"] == skillpath:
                        result["status_updates"] += skillset_status.split(',')
                        result["state_description"] = skillset_status.split(',')[-1]
                        if result["state"] != "Error":
                            result["state"] = "Complete"
                        final_e["state"] = result["state"]
                        final_e["status_updates"] = ','.join(result["status_updates"])
                        table_client.upsert_entity(entity={
                            "PartitionKey": urllib.parse.quote(result["file_path"], safe=''),
                            "RowKey": result["file_name"],
                            "state": final_e["state"],
                        })
                    
        

    except Exception as ex:
        log.exception("Exception in /getalluploadstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.post("/getfolders")
async def get_folders():
    """
    Get all folders.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: list of unique folders.
    """
    try:
        upload_blob_container = blob_client.get_container_client(
            os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        # Initialize an empty list to hold the folder paths
        folders = []
        # List all blobs in the container
        blob_list = upload_blob_container.list_blobs()
        # Iterate through the blobs and extract folder names and add unique values to the list
        for blob in blob_list:
            # Extract the folder path if exists
            folder_path = os.path.dirname(blob.name)
            if folder_path and folder_path not in folders:
                folders.append(folder_path)
    except Exception as ex:
        log.exception("Exception in /getfolders")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return folders


@app.post("/deleteItems")
async def delete_Items(request: Request):
    """
    Delete a blob.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: list of unique folders.
    """
    json_body = await request.json()
    full_path = json_body.get("path")
    # remove the container prefix
    path = full_path.split("/", 1)[1]
    try:
        upload_blob_container = blob_client.get_container_client(
            os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        upload_blob_container.delete_blob(path)

        # Add the logs to the status table
        file_path, filename = os.path.split(full_path)
        entity = {
            "PartitionKey": urllib.parse.quote(file_path, safe=''),
            "RowKey": filename,
            "status": "File deleted",
            "status_classification": StatusLogClassification.INFO,
            "state": StatusLogState.DELETED
        }
        table_client = table_service_client.get_table_client(
            table_name=UPLOAD_TABLE_NAME)
        table_client.upsert_entity(entity=entity)

    except Exception as ex:
        log.exception("Exception in /delete_Items")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return True


@app.post("/resubmitItems")
async def resubmit_Items(request: Request):
    """
    Resubmit a blob.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: list of unique folders.
    """
    json_body = await request.json()
    full_path = json_body.get("path")
    path = full_path.split("/", 1)[1]
    # remove the container prefix
    try:
        upload_blob_container = blob_client.get_container_client(
            os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        # Read the blob content into memory
        blob_data = upload_blob_container.download_blob(path).readall()

        submitted_blob_client = upload_blob_container.get_blob_client(blob=path)
        blob_properties = submitted_blob_client.get_blob_properties()
        metadata = blob_properties.metadata
        upload_blob_container.upload_blob(
            name=path, data=blob_data, overwrite=True, metadata=metadata) 
        
        # Add the logs to the status table
        file_path, filename = os.path.split(full_path)
        entity = {
            "PartitionKey": urllib.parse.quote(file_path, safe=''),
            "RowKey": filename,
            "status": "File resubmitted",
            "status_classification": StatusLogClassification.INFO,
            "state": StatusLogState.RESUBMITTED
        }
        table_client = table_service_client.get_table_client(
            table_name=UPLOAD_TABLE_NAME)
        table_client.upsert_entity(entity=entity)

    except Exception as ex:
        log.exception("Exception in /resubmitItems")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return True


@app.post("/gettags")
async def get_tags(request: Request):
    """
    Get all tags.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: list of unique tags.
    """
    try:
        # Initialize an empty list to hold the tags
        unique_tags = set()
        table_client = table_service_client.get_table_client(table_name=UPLOAD_TABLE_NAME)
        entities = list(table_client.list_entities())
        for entity in entities:
            entity_tags = entity.get("tags", '').split(',')
            for tag in entity_tags:
                trimmed_tag = tag.strip()
                if trimmed_tag:
                    unique_tags.add(trimmed_tag)

    except Exception as ex:
        log.exception("Exception in /gettags")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return unique_tags


@app.post("/logstatus")
async def logstatus(request: Request):
    """
    Log the status of a file upload to Azure Table Storage.

    Parameters:
    - request: Request object containing the HTTP request data.

    Returns:
    - An HTTPException with the status code 200 if successful, or an error
        message with status code 500 if an exception occurs.
    """
    try:
        json_body = await request.json()

        file_path = json_body.get("path", "")
        created_timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
        tags = json_body.get("tags", [])
        tags_str = ",".join(tags)
        path, filename = os.path.split(file_path)
        sanitized_path = urllib.parse.quote(path, safe='')
        entity = {
            "PartitionKey": sanitized_path,
            "RowKey": filename,
            "status": json_body.get("status", ""),
            "status_classification": json_body.get("status_classification", ""),
            "state": json_body.get("state", ""),
            "created_timestamp": created_timestamp,
            "tags": tags_str
        }
        # Add the logs to the status table
        table_client = table_service_client.get_table_client(
            table_name=UPLOAD_TABLE_NAME)
        table_client.upsert_entity(entity=entity)


    except Exception as ex:
        log.exception("Exception in /logstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    raise HTTPException(status_code=200, detail="Success")


@app.get("/getInfoData")
async def get_info_data():
    """
    Get the info data for the app.

    Returns:
        dict: A dictionary containing various information data for the app.
            -"AZURE_OPENAI_CHATGPT_DEPLOYMENT": The deployment information for Azure OpenAI ChatGPT.
            - "AZURE_OPENAI_MODEL_NAME": The name of the Azure OpenAI model.
            - "AZURE_OPENAI_MODEL_VERSION": The version of the Azure OpenAI model.
            - "AZURE_OPENAI_SERVICE": The Azure OpenAI service information.
            - "AZURE_SEARCH_SERVICE": The Azure search service information.
            - "AZURE_SEARCH_INDEX": The Azure search index information.
            - "TARGET_LANGUAGE": The target language for query terms.
            - "EMBEDDINGS_DEPLOYMENT": The deployment information for embeddings.
            - "EMBEDDINGS_MODEL_NAME": The name of the embeddings model.
            - "EMBEDDINGS_MODEL_VERSION": The version of the embeddings model.
    """
    response = {
        "AZURE_OPENAI_CHATGPT_DEPLOYMENT": ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        "AZURE_OPENAI_MODEL_NAME": f"{MODEL_NAME}",
        "AZURE_OPENAI_MODEL_VERSION": f"{MODEL_VERSION}",
        "AZURE_OPENAI_SERVICE": ENV["AZURE_OPENAI_SERVICE"],
        "AZURE_SEARCH_SERVICE": ENV["AZURE_SEARCH_SERVICE"],
        "AZURE_SEARCH_INDEX": ENV["AZURE_SEARCH_INDEX"],
        "TARGET_LANGUAGE": ENV["QUERY_TERM_LANGUAGE"],
        "EMBEDDINGS_DEPLOYMENT": ENV["EMBEDDING_DEPLOYMENT_NAME"],
        "EMBEDDINGS_MODEL_NAME": f"{EMBEDDING_MODEL_NAME}",
        "EMBEDDINGS_MODEL_VERSION": f"{EMBEDDING_MODEL_VERSION}",
    }
    return response


@app.get("/getWarningBanner")
async def get_warning_banner():
    """Get the warning banner text"""
    response = {
        "WARNING_BANNER_TEXT": ENV["CHAT_WARNING_BANNER_TEXT"]
    }
    return response


@app.post("/getcitation")
async def get_citation(request: Request):
    """
    Get the citation for a given file

    Parameters:
        request (Request): The HTTP request object

    Returns:
        dict: The citation results in JSON format
    """
    try:
        json_body = await request.json()
        citation = urllib.parse.unquote(json_body.get("citation"))
        blob = blob_container.get_blob_client(citation).download_blob()
        decoded_text = blob.readall().decode()
        results = json.loads(decoded_text)
    except Exception as ex:
        log.exception("Exception in /getcitation")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

# Return APPLICATION_TITLE


@app.get("/getApplicationTitle")
async def get_application_title():
    """Get the application title text

    Returns:
        dict: A dictionary containing the application title.
    """
    response = {
        "APPLICATION_TITLE": ENV["APPLICATION_TITLE"]
    }
    return response


@app.get("/getalltags")
async def get_all_tags():
    """
    Get the status of all tags in the system

    Returns:
        list: A list containing all tags
    """
    try:
        unique_tags = set()
        table_client = table_service_client.get_table_client(table_name=UPLOAD_TABLE_NAME)
        entities = list(table_client.list_entities())
        for entity in entities:
            entity_tags = entity.get("tags", '').split(',')
            for tag in entity_tags:
                if tag:
                    tag = tag.strip()
                    unique_tags.add(tag)
    except Exception as ex:
        log.exception("Exception in /getalltags")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return list(unique_tags)


@app.get("/getFeatureFlags")
async def get_feature_flags():
    """
    Get the feature flag settings for the app.

    Returns:
        dict: A dictionary containing various feature flags for the app.
            - "USE_WEB_CHAT": Flag indicating whether web chat is enabled.
            - "USE_UNGROUNDED_CHAT": Flag indicating whether ungrounded chat is enabled.
            """
    response = {
        "USE_WEB_CHAT": str_to_bool.get(ENV["USE_WEB_CHAT"]),
        "USE_UNGROUNDED_CHAT": str_to_bool.get(ENV["USE_UNGROUNDED_CHAT"]),
    }
    return response


@app.post("/file")
async def upload_file(
    file: UploadFile = File(...),
    file_path: str = Form(...),
    tags: str = Form(None)
):
    """  
    Upload a file to Azure Blob Storage.  
    Parameters:  
    - file: The file to upload.
    - file_path: The path to save the file in Blob Storage.
    - tags: The tags to associate with the file.  
    Returns:  
    - response: A message indicating the result of the upload.  
    """
    try:
        blob_upload_client = blob_upload_container_client.get_blob_client(
            file_path)
        blob_upload_client.upload_blob(
            file.file,
            overwrite=True,
            content_settings=ContentSettings(content_type=file.content_type),
            metadata={"tags": tags}
        )

        return {"message": f"File '{file.filename}' uploaded successfully"}

    except Exception as ex:
        log.exception("Exception in /file")
        raise HTTPException(status_code=500, detail=str(ex)) from ex


@app.post("/get-file")
async def get_file(request: Request):
    data = await request.json()
    file_path = data['path']

    # Extract container name and blob name from the file path
    container_name, blob_name = file_path.split('/', 1)

    # Download the blob to a local file

    citation_blob_client = blob_upload_container_client.get_blob_client(
        blob=blob_name)
    stream = citation_blob_client.download_blob().chunks()
    blob_properties = citation_blob_client.get_blob_properties()

    return StreamingResponse(stream,
                             media_type=blob_properties.content_settings.content_type,
                             headers={"Content-Disposition": f"inline; filename={blob_name}"})

app.mount("/", StaticFiles(directory="static"), name="static")

if __name__ == "__main__":
    log.info("IA WebApp Starting Up...")
