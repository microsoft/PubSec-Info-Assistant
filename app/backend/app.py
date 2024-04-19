# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
from io import StringIO
from typing import Optional
import asyncio
#from sse_starlette.sse import EventSourceResponse
#from starlette.responses import StreamingResponse
from starlette.responses import Response
import logging
import os
import json
import urllib.parse
import pandas as pd
from datetime import datetime, time, timedelta
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import RedirectResponse, StreamingResponse
import openai
from approaches.comparewebwithwork import CompareWebWithWork
from approaches.compareworkwithweb import CompareWorkWithWeb
from approaches.chatreadretrieveread import ChatReadRetrieveReadApproach
from approaches.chatwebretrieveread import ChatWebRetrieveRead
from approaches.gpt_direct_approach import GPTDirectApproach
from approaches.approach import Approaches
from azure.core.credentials import AzureKeyCredential
from azure.identity import DefaultAzureCredential, AzureAuthorityHosts
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from azure.search.documents import SearchClient
from azure.storage.blob import (
    AccountSasPermissions,
    BlobServiceClient,
    ResourceTypes,
    generate_account_sas,
)
from approaches.mathassistant import(
    generate_response,
    process_agent_scratch_pad,
    process_agent_response,
    stream_agent_responses
)
from approaches.tabulardataassistant import (
    refreshagent,
    save_df,
    process_agent_response as td_agent_response,
    process_agent_scratch_pad as td_agent_scratch_pad,
    get_images_in_temp

)
from shared_code.status_log import State, StatusClassification, StatusLog, StatusQueryLevel
from azure.cosmos import CosmosClient


# === ENV Setup ===

ENV = {
    "AZURE_BLOB_STORAGE_ACCOUNT": None,
    "AZURE_BLOB_STORAGE_ENDPOINT": None,
    "AZURE_BLOB_STORAGE_KEY": None,
    "AZURE_BLOB_STORAGE_CONTAINER": "content",
    "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER": "upload",
    "AZURE_SEARCH_SERVICE": "gptkb",
    "AZURE_SEARCH_SERVICE_ENDPOINT": None,
    "AZURE_SEARCH_SERVICE_KEY": None,
    "AZURE_SEARCH_INDEX": "gptkbindex",
    "USE_SEMANTIC_RERANKER": "true",
    "AZURE_OPENAI_SERVICE": "myopenai",
    "AZURE_OPENAI_RESOURCE_GROUP": "",
    "AZURE_OPENAI_ENDPOINT": "",
    "AZURE_OPENAI_AUTHORITY_HOST": "AzureCloud",
    "AZURE_OPENAI_CHATGPT_DEPLOYMENT": "gpt-35-turbo-16k",
    "AZURE_OPENAI_CHATGPT_MODEL_NAME": "",
    "AZURE_OPENAI_CHATGPT_MODEL_VERSION": "",
    "USE_AZURE_OPENAI_EMBEDDINGS": "false",
    "EMBEDDING_DEPLOYMENT_NAME": "",
    "AZURE_OPENAI_EMBEDDINGS_MODEL_NAME": "",
    "AZURE_OPENAI_EMBEDDINGS_VERSION": "",
    "AZURE_OPENAI_SERVICE_KEY": None,
    "AZURE_SUBSCRIPTION_ID": None,
    "AZURE_ARM_MANAGEMENT_API": "https://management.azure.com",
    "CHAT_WARNING_BANNER_TEXT": "",
    "APPLICATION_TITLE": "Information Assistant, built with Azure OpenAI",
    "KB_FIELDS_CONTENT": "content",
    "KB_FIELDS_PAGENUMBER": "pages",
    "KB_FIELDS_SOURCEFILE": "file_uri",
    "KB_FIELDS_CHUNKFILE": "chunk_file",
    "COSMOSDB_URL": None,
    "COSMOSDB_KEY": None,
    "COSMOSDB_LOG_DATABASE_NAME": "statusdb",
    "COSMOSDB_LOG_CONTAINER_NAME": "statuscontainer",
    "QUERY_TERM_LANGUAGE": "English",
    "TARGET_EMBEDDINGS_MODEL": "BAAI/bge-small-en-v1.5",
    "ENRICHMENT_APPSERVICE_URL": "enrichment",
    "TARGET_TRANSLATION_LANGUAGE": "en",
    "ENRICHMENT_ENDPOINT": None,
    "ENRICHMENT_KEY": None,
    "AZURE_AI_TRANSLATION_DOMAIN": "api.cognitive.microsofttranslator.com",
    "BING_SEARCH_ENDPOINT": "https://api.bing.microsoft.com/",
    "BING_SEARCH_KEY": "",
    "ENABLE_BING_SAFE_SEARCH": "true",
    "ENABLE_WEB_CHAT": "false",
    "ENABLE_UNGROUNDED_CHAT": "false",
    "ENABLE_MATH_ASSISTANT": "false",
    "ENABLE_TABULAR_DATA_ASSISTANT": "false",
    "ENABLE_MULTIMEDIA": "false",
    "MAX_CSV_FILE_SIZE": "7"
    }

for key, value in ENV.items():
    new_value = os.getenv(key)
    if new_value is not None:
        ENV[key] = new_value
    elif value is None:
        raise ValueError(f"Environment variable {key} not set")

str_to_bool = {'true': True, 'false': False}

log = logging.getLogger("uvicorn")
log.setLevel('DEBUG')
log.propagate = True

dffinal = None
# Used by the OpenAI SDK
openai.api_type = "azure"
openai.api_base = ENV["AZURE_OPENAI_ENDPOINT"]
if ENV["AZURE_OPENAI_AUTHORITY_HOST"] == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD
openai.api_version = "2024-02-01"
# Use the current user identity to authenticate with Azure OpenAI, Cognitive Search and Blob Storage (no secrets needed,
# just use 'az login' locally, and managed identity when deployed on Azure). If you need to use keys, use separate AzureKeyCredential instances with the
# keys for each service
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
azure_credential = DefaultAzureCredential(authority=AUTHORITY)
# Comment these two lines out if using keys, set your API key in the OPENAI_API_KEY environment variable instead
# openai.api_type = "azure_ad"
# openai_token = azure_credential.get_token("https://cognitiveservices.azure.com/.default")
openai.api_key = ENV["AZURE_OPENAI_SERVICE_KEY"]

# Setup StatusLog to allow access to CosmosDB for logging
statusLog = StatusLog(
    ENV["COSMOSDB_URL"],
    ENV["COSMOSDB_KEY"],
    ENV["COSMOSDB_LOG_DATABASE_NAME"],
    ENV["COSMOSDB_LOG_CONTAINER_NAME"]
)

azure_search_key_credential = AzureKeyCredential(ENV["AZURE_SEARCH_SERVICE_KEY"])
# Set up clients for Cognitive Search and Storage
search_client = SearchClient(
    endpoint=ENV["AZURE_SEARCH_SERVICE_ENDPOINT"],
    index_name=ENV["AZURE_SEARCH_INDEX"],
    credential=azure_search_key_credential,
)
blob_client = BlobServiceClient(
    account_url=ENV["AZURE_BLOB_STORAGE_ENDPOINT"],
    credential=ENV["AZURE_BLOB_STORAGE_KEY"],
)
blob_container = blob_client.get_container_client(ENV["AZURE_BLOB_STORAGE_CONTAINER"])

model_name = ''
model_version = ''

# Set up OpenAI management client
openai_mgmt_client = CognitiveServicesManagementClient(
    credential=azure_credential,
    subscription_id=ENV["AZURE_SUBSCRIPTION_ID"],
    base_url=ENV["AZURE_ARM_MANAGEMENT_API"])

deployment = openai_mgmt_client.deployments.get(
    resource_group_name=ENV["AZURE_OPENAI_RESOURCE_GROUP"],
    account_name=ENV["AZURE_OPENAI_SERVICE"],
    deployment_name=ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"])

model_name = deployment.properties.model.name
model_version = deployment.properties.model.version

if (str_to_bool.get(ENV["USE_AZURE_OPENAI_EMBEDDINGS"])):
    embedding_deployment = openai_mgmt_client.deployments.get(
        resource_group_name=ENV["AZURE_OPENAI_RESOURCE_GROUP"],
        account_name=ENV["AZURE_OPENAI_SERVICE"],
        deployment_name=ENV["EMBEDDING_DEPLOYMENT_NAME"])

    embedding_model_name = embedding_deployment.properties.model.name
    embedding_model_version = embedding_deployment.properties.model.version
else:
    embedding_model_name = ""
    embedding_model_version = ""

chat_approaches = {
    Approaches.ReadRetrieveRead: ChatReadRetrieveReadApproach(
                                    search_client,
                                    ENV["AZURE_OPENAI_ENDPOINT"],
                                    ENV["AZURE_OPENAI_SERVICE_KEY"],
                                    ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
                                    ENV["KB_FIELDS_SOURCEFILE"],
                                    ENV["KB_FIELDS_CONTENT"],
                                    ENV["KB_FIELDS_PAGENUMBER"],
                                    ENV["KB_FIELDS_CHUNKFILE"],
                                    ENV["AZURE_BLOB_STORAGE_CONTAINER"],
                                    blob_client,
                                    ENV["QUERY_TERM_LANGUAGE"],
                                    model_name,
                                    model_version,
                                    ENV["TARGET_EMBEDDINGS_MODEL"],
                                    ENV["ENRICHMENT_APPSERVICE_URL"],
                                    ENV["TARGET_TRANSLATION_LANGUAGE"],
                                    ENV["ENRICHMENT_ENDPOINT"],
                                    ENV["ENRICHMENT_KEY"],
                                    ENV["AZURE_AI_TRANSLATION_DOMAIN"],
                                    str_to_bool.get(ENV["USE_SEMANTIC_RERANKER"])
                                ),
    Approaches.ChatWebRetrieveRead: ChatWebRetrieveRead(
                                    model_name,
                                    ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
                                    ENV["TARGET_TRANSLATION_LANGUAGE"],
                                    ENV["BING_SEARCH_ENDPOINT"],
                                    ENV["BING_SEARCH_KEY"],
                                    str_to_bool.get(ENV["ENABLE_BING_SAFE_SEARCH"])
    ),
    Approaches.CompareWorkWithWeb: CompareWorkWithWeb( 
                                    model_name,
                                    ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
                                    ENV["TARGET_TRANSLATION_LANGUAGE"],
                                    ENV["BING_SEARCH_ENDPOINT"],
                                    ENV["BING_SEARCH_KEY"],
                                    str_to_bool.get(ENV["ENABLE_BING_SAFE_SEARCH"])
    ),
    Approaches.CompareWebWithWork: CompareWebWithWork(
                                    search_client,
                                    ENV["AZURE_OPENAI_ENDPOINT"],
                                    ENV["AZURE_OPENAI_SERVICE_KEY"],
                                    ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
                                    ENV["KB_FIELDS_SOURCEFILE"],
                                    ENV["KB_FIELDS_CONTENT"],
                                    ENV["KB_FIELDS_PAGENUMBER"],
                                    ENV["KB_FIELDS_CHUNKFILE"],
                                    ENV["AZURE_BLOB_STORAGE_CONTAINER"],
                                    blob_client,
                                    ENV["QUERY_TERM_LANGUAGE"],
                                    model_name,
                                    model_version,
                                    ENV["TARGET_EMBEDDINGS_MODEL"],
                                    ENV["ENRICHMENT_APPSERVICE_URL"],
                                    ENV["TARGET_TRANSLATION_LANGUAGE"],
                                    ENV["ENRICHMENT_ENDPOINT"],
                                    ENV["ENRICHMENT_KEY"],
                                    ENV["AZURE_AI_TRANSLATION_DOMAIN"],
                                    str_to_bool.get(ENV["USE_SEMANTIC_RERANKER"])
                                ),
    Approaches.GPTDirect: GPTDirectApproach(
                                ENV["AZURE_OPENAI_SERVICE"],
                                ENV["AZURE_OPENAI_SERVICE_KEY"],
                                ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
                                ENV["QUERY_TERM_LANGUAGE"],
                                model_name,
                                model_version,
                                ENV["AZURE_OPENAI_ENDPOINT"]
    )
}

# Create API
app = FastAPI(
    title="IA Web API",
    description="A Python API to serve as Backend For the Information Assistant Web App",
    version="0.1.0",
    docs_url="/docs",
)

@app.get("/", include_in_schema=False, response_class=RedirectResponse)
async def root():
    """Redirect to the index.html page"""
    return RedirectResponse(url="/index.html")


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
        
        if (Approaches(int(approach)) == Approaches.CompareWorkWithWeb or Approaches(int(approach)) == Approaches.CompareWebWithWork):
            r = await impl.run(json_body.get("history", []), json_body.get("overrides", {}), json_body.get("citation_lookup", {}), json_body.get("thought_chain", {}))
        else:
            r = await impl.run(json_body.get("history", []), json_body.get("overrides", {}), {}, json_body.get("thought_chain", {}))
       
        response = {
                "data_points": r["data_points"],
                "answer": r["answer"],
                "thoughts": r["thoughts"],
                "thought_chain": r["thought_chain"],
                "work_citation_lookup": r["work_citation_lookup"],
                "web_citation_lookup": r["web_citation_lookup"]
        }

        return response

    except Exception as ex:
        log.error(f"Error in chat:: {ex}")
        raise HTTPException(status_code=500, detail=str(ex)) from ex


    

@app.get("/getblobclienturl")
async def get_blob_client_url():
    """Get a URL for a file in Blob Storage with SAS token.

    This function generates a Shared Access Signature (SAS) token for accessing a file in Blob Storage.
    The generated URL includes the SAS token as a query parameter.

    Returns:
        dict: A dictionary containing the URL with the SAS token.
    """
    sas_token = generate_account_sas(
        ENV["AZURE_BLOB_STORAGE_ACCOUNT"],
        ENV["AZURE_BLOB_STORAGE_KEY"],
        resource_types=ResourceTypes(object=True, service=True, container=True),
        permission=AccountSasPermissions(
            read=True,
            write=True,
            list=True,
            delete=False,
            add=True,
            create=True,
            update=True,
            process=False,
        ),
        expiry=datetime.utcnow() + timedelta(hours=1),
    )
    return {"url": f"{blob_client.url}?{sas_token}"}

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
    timeframe = json_body.get("timeframe")
    state = json_body.get("state")
    folder = json_body.get("folder")
    tag = json_body.get("tag")   
    try:
        results = statusLog.read_files_status_by_timeframe(timeframe, 
            State[state], 
            folder, 
            tag,
            os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])

        # retrieve tags for each file
         # Initialize an empty list to hold the tags
        items = []              
        cosmos_client = CosmosClient(url=statusLog._url, credential=statusLog._key)
        database = cosmos_client.get_database_client(statusLog._database_name)
        container = database.get_container_client(statusLog._container_name)
        query_string = "SELECT DISTINCT VALUE t FROM c JOIN t IN c.tags"
        items = list(container.query_items(
            query=query_string,
            enable_cross_partition_query=True
        ))           

        # Extract and split tags
        unique_tags = set()
        for item in items:
            tags = item.split(',')
            unique_tags.update(tags)        

        
    except Exception as ex:
        log.exception("Exception in /getalluploadstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.post("/getfolders")
async def get_folders(request: Request):
    """
    Get all folders.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: list of unique folders.
    """
    try:
        blob_container = blob_client.get_container_client(os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        # Initialize an empty list to hold the folder paths
        folders = []
        # List all blobs in the container
        blob_list = blob_container.list_blobs()
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
        blob_container = blob_client.get_container_client(os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        blob_container.delete_blob(path)
        statusLog.upsert_document(document_path=full_path,
            status='Delete intiated',
            status_classification=StatusClassification.INFO,
            state=State.DELETING,
            fresh_start=False)
        statusLog.save_document(document_path=full_path)   

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
    path = json_body.get("path")
    # remove the container prefix
    path = path.split("/", 1)[1]
    try:
        blob_container = blob_client.get_container_client(os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"])
        # Read the blob content into memory
        blob_data = blob_container.download_blob(path).readall()
        # Overwrite the blob with the modified data
        blob_container.upload_blob(name=path, data=blob_data, overwrite=True)  
        # add the container to the path to avoid adding another doc in the status db
        full_path = os.environ["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"] + '/' + path
        statusLog.upsert_document(document_path=full_path,
                    status='Resubmitted to the processing pipeline',
                    status_classification=StatusClassification.INFO,
                    state=State.QUEUED,
                    fresh_start=False)
        statusLog.save_document(document_path=full_path)   

    except Exception as ex:
        log.exception("Exception in /delete_Items")
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
        items = []              
        cosmos_client = CosmosClient(url=statusLog._url, credential=statusLog._key)     
        database = cosmos_client.get_database_client(statusLog._database_name)               
        container = database.get_container_client(statusLog._container_name) 
        query_string = "SELECT DISTINCT VALUE t FROM c JOIN t IN c.tags"  
        items = list(container.query_items(
            query=query_string,
            enable_cross_partition_query=True
        ))           

        # Extract and split tags
        unique_tags = set()
        for item in items:
            tags = item.split(',')
            unique_tags.update(tags)                  
                
    except Exception as ex:
        log.exception("Exception in /gettags")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return unique_tags

@app.post("/logstatus")
async def logstatus(request: Request):
    """
    Log the status of a file upload to CosmosDB.

    Parameters:
    - request: Request object containing the HTTP request data.

    Returns:
    - A dictionary with the status code 200 if successful, or an error
        message with status code 500 if an exception occurs.
    """
    try:
        json_body = await request.json()
        path = json_body.get("path")
        status = json_body.get("status")
        status_classification = StatusClassification[json_body.get("status_classification").upper()]
        state = State[json_body.get("state").upper()]

        statusLog.upsert_document(document_path=path,
                                  status=status,
                                  status_classification=status_classification,
                                  state=state,
                                  fresh_start=True)
        statusLog.save_document(document_path=path)

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
            - "AZURE_OPENAI_CHATGPT_DEPLOYMENT": The deployment information for Azure OpenAI ChatGPT.
            - "AZURE_OPENAI_MODEL_NAME": The name of the Azure OpenAI model.
            - "AZURE_OPENAI_MODEL_VERSION": The version of the Azure OpenAI model.
            - "AZURE_OPENAI_SERVICE": The Azure OpenAI service information.
            - "AZURE_SEARCH_SERVICE": The Azure search service information.
            - "AZURE_SEARCH_INDEX": The Azure search index information.
            - "TARGET_LANGUAGE": The target language for query terms.
            - "USE_AZURE_OPENAI_EMBEDDINGS": Flag indicating whether to use Azure OpenAI embeddings.
            - "EMBEDDINGS_DEPLOYMENT": The deployment information for embeddings.
            - "EMBEDDINGS_MODEL_NAME": The name of the embeddings model.
            - "EMBEDDINGS_MODEL_VERSION": The version of the embeddings model.
    """
    response = {
        "AZURE_OPENAI_CHATGPT_DEPLOYMENT": ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
        "AZURE_OPENAI_MODEL_NAME": f"{model_name}",
        "AZURE_OPENAI_MODEL_VERSION": f"{model_version}",
        "AZURE_OPENAI_SERVICE": ENV["AZURE_OPENAI_SERVICE"],
        "AZURE_SEARCH_SERVICE": ENV["AZURE_SEARCH_SERVICE"],
        "AZURE_SEARCH_INDEX": ENV["AZURE_SEARCH_INDEX"],
        "TARGET_LANGUAGE": ENV["QUERY_TERM_LANGUAGE"],
        "USE_AZURE_OPENAI_EMBEDDINGS": ENV["USE_AZURE_OPENAI_EMBEDDINGS"],
        "EMBEDDINGS_DEPLOYMENT": ENV["EMBEDDING_DEPLOYMENT_NAME"],
        "EMBEDDINGS_MODEL_NAME": f"{embedding_model_name}",
        "EMBEDDINGS_MODEL_VERSION": f"{embedding_model_version}",
    }
    return response


@app.get("/getWarningBanner")
async def get_warning_banner():
    """Get the warning banner text"""
    response ={
            "WARNING_BANNER_TEXT": ENV["CHAT_WARNING_BANNER_TEXT"]
        }
    return response

@app.get("/getMaxCSVFileSize")
async def get_max_csv_file_size():
    """Get the max csv size"""
    response ={
            "MAX_CSV_FILE_SIZE": ENV["MAX_CSV_FILE_SIZE"]
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
        dict: A dictionary containing the status of all tags
    """
    try:
        results = statusLog.get_all_tags()
    except Exception as ex:
        log.exception("Exception in /getalltags")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.get("/getTempImages")
async def get_temp_images():
    """Get the images in the temp directory

    Returns:
        list: A list of image data in the temp directory.
    """
    images = get_images_in_temp()
    return {"images": images}

@app.get("/getHint")
async def getHint(question: Optional[str] = None):
    """
    Get the hint for a question

    Returns:
        str: A string containing the hint
    """
    if question is None:
        raise HTTPException(status_code=400, detail="Question is required")

    try:
        results = generate_response(question).split("Clues")[1][2:]
    except Exception as ex:
        log.exception("Exception in /getHint")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.post("/posttd")
async def posttd(csv: UploadFile = File(...)):
    try:
        global dffinal
            # Read the file into a pandas DataFrame
        content = await csv.read()
        df = pd.read_csv(StringIO(content.decode('latin-1')))

        dffinal = df
        # Process the DataFrame...
        save_df(df)
    except Exception as ex:
            raise HTTPException(status_code=500, detail=str(ex)) from ex
    
    
    #return {"filename": csv.filename}
@app.get("/process_td_agent_response")
async def process_td_agent_response(retries=3, delay=1000, question: Optional[str] = None):
    if question is None:
        raise HTTPException(status_code=400, detail="Question is required")
    for i in range(retries):
        try:
            results = td_agent_response(question)
            return results
        except AttributeError as ex:
            log.exception(f"Exception in /process_tabular_data_agent_response:{str(ex)}")
            if i < retries - 1:  # i is zero indexed
                await asyncio.sleep(delay)  # wait a bit before trying again
            else:
                if str(ex) == "'NoneType' object has no attribute 'stream'":
                    return ["error: Csv has not been loaded"]
                else:
                    raise HTTPException(status_code=500, detail=str(ex)) from ex
        except Exception as ex:
            log.exception(f"Exception in /process_tabular_data_agent_response:{str(ex)}")
            if i < retries - 1:  # i is zero indexed
                await asyncio.sleep(delay)  # wait a bit before trying again
            else:
                raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.get("/getTdAnalysis")
async def getTdAnalysis(retries=3, delay=1, question: Optional[str] = None):
    global dffinal
    if question is None:
            raise HTTPException(status_code=400, detail="Question is required")
        
    for i in range(retries):
        try:
            save_df(dffinal)
            results = td_agent_scratch_pad(question, dffinal)
            return results
        except AttributeError as ex:
            log.exception(f"Exception in /getTdAnalysis:{str(ex)}")
            if i < retries - 1:  # i is zero indexed
                await asyncio.sleep(delay)  # wait a bit before trying again
            else:
                if str(ex) == "'NoneType' object has no attribute 'stream'":
                    return ["error: Csv has not been loaded"]
                else:
                    raise HTTPException(status_code=500, detail=str(ex)) from ex
        except Exception as ex:
            log.exception(f"Exception in /getTdAnalysis:{str(ex)}")
            if i < retries - 1:  # i is zero indexed
                await asyncio.sleep(delay)  # wait a bit before trying again
            else:
                raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.post("/refresh")
async def refresh():
    """
    Refresh the agent's state.

    This endpoint calls the `refresh` function to reset the agent's state.

    Raises:
        HTTPException: If an error occurs while refreshing the agent's state.

    Returns:
        dict: A dictionary containing the status of the agent's state.
    """
    try:
        refreshagent()
    except Exception as ex:
        log.exception("Exception in /refresh")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return {"status": "success"}

@app.get("/getSolve")
async def getSolve(question: Optional[str] = None):
   
    if question is None:
        raise HTTPException(status_code=400, detail="Question is required")

    try:
        results = process_agent_scratch_pad(question)
    except Exception as ex:
        log.exception("Exception in /getSolve")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results


@app.get("/stream")
async def stream_response(question: str):
    try:
        stream = stream_agent_responses(question)
        return StreamingResponse(stream, media_type="text/event-stream")
    except Exception as ex:
        log.exception("Exception in /stream")
        raise HTTPException(status_code=500, detail=str(ex)) from ex

@app.get("/tdstream")
async def td_stream_response(question: str):
    save_df(dffinal)
    

    try:
        stream = td_agent_scratch_pad(question, dffinal)
        return StreamingResponse(stream, media_type="text/event-stream")
    except Exception as ex:
        log.exception("Exception in /stream")
        raise HTTPException(status_code=500, detail=str(ex)) from ex




@app.get("/process_agent_response")
async def stream_agent_response(question: str):
    """
    Stream the response of the agent for a given question.

    This endpoint uses Server-Sent Events (SSE) to stream the response of the agent. 
    It calls the `process_agent_response` function which yields chunks of data as they become available.

    Args:
        question (str): The question to be processed by the agent.

    Yields:
        dict: A dictionary containing a chunk of the agent's response.

    Raises:
        HTTPException: If an error occurs while processing the question.
    """
    # try:
    #     def event_stream():
    #         data_generator = iter(process_agent_response(question))
    #         while True:
    #             try:
    #                 chunk = next(data_generator)
    #                 yield chunk
    #             except StopIteration:
    #                 yield "data: keep-alive\n\n"
    #                 time.sleep(5)
    #     return StreamingResponse(event_stream(), media_type="text/event-stream")
    if question is None:
        raise HTTPException(status_code=400, detail="Question is required")

    try:
        results = process_agent_response(question)
    except Exception as e:
        print(f"Error processing agent response: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    return results


@app.get("/getFeatureFlags")
async def get_feature_flags():
    """
    Get the feature flag settings for the app.

    Returns:
        dict: A dictionary containing various feature flags for the app.
            - "ENABLE_WEB_CHAT": Flag indicating whether web chat is enabled.
            - "ENABLE_UNGROUNDED_CHAT": Flag indicating whether ungrounded chat is enabled.
            - "ENABLE_MATH_ASSISTANT": Flag indicating whether the math assistant is enabled.
            - "ENABLE_TABULAR_DATA_ASSISTANT": Flag indicating whether the tabular data assistant is enabled.
            - "ENABLE_MULTIMEDIA": Flag indicating whether multimedia is enabled.
    """
    response = {
        "ENABLE_WEB_CHAT": str_to_bool.get(ENV["ENABLE_WEB_CHAT"]),
        "ENABLE_UNGROUNDED_CHAT": str_to_bool.get(ENV["ENABLE_UNGROUNDED_CHAT"]),
        "ENABLE_MATH_ASSISTANT": str_to_bool.get(ENV["ENABLE_MATH_ASSISTANT"]),
        "ENABLE_TABULAR_DATA_ASSISTANT": str_to_bool.get(ENV["ENABLE_TABULAR_DATA_ASSISTANT"]),
        "ENABLE_MULTIMEDIA": str_to_bool.get(ENV["ENABLE_MULTIMEDIA"]),
    }
    return response

app.mount("/", StaticFiles(directory="static"), name="static")

if __name__ == "__main__":
    log.info("IA WebApp Starting Up...")
