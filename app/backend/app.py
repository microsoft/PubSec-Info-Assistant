# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import json
import urllib.parse
from datetime import datetime, timedelta
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import RedirectResponse
import openai
from approaches.chatreadretrieveread import ChatReadRetrieveReadApproach
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
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.tags_helper import TagsHelper



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
    "COSMOSDB_TAGS_DATABASE_NAME": "tagsdb",
    "COSMOSDB_TAGS_CONTAINER_NAME": "tagscontainer",
    "QUERY_TERM_LANGUAGE": "English",
    "TARGET_EMBEDDINGS_MODEL": "BAAI/bge-small-en-v1.5",
    "ENRICHMENT_APPSERVICE_URL": "enrichment",
    "TARGET_TRANSLATION_LANGUAGE": "en",
    "ENRICHMENT_ENDPOINT": None,
    "ENRICHMENT_KEY": None,
    "AZURE_AI_TRANSLATION_DOMAIN": "api.cognitive.microsofttranslator.com"
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

# Used by the OpenAI SDK
openai.api_type = "azure"
openai.api_base = ENV["AZURE_OPENAI_ENDPOINT"]
if ENV["AZURE_OPENAI_AUTHORITY_HOST"] == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD
openai.api_version = "2023-12-01-preview"

# Use the current user identity to authenticate with Azure OpenAI, Cognitive Search and Blob Storage (no secrets needed,
# just use 'az login' locally, and managed identity when deployed on Azure). If you need to use keys, use separate AzureKeyCredential instances with the
# keys for each service
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
azure_credential = DefaultAzureCredential(authority=AUTHORITY)
azure_search_key_credential = AzureKeyCredential(ENV["AZURE_SEARCH_SERVICE_KEY"])

# Setup StatusLog to allow access to CosmosDB for logging
statusLog = StatusLog(
    ENV["COSMOSDB_URL"],
    ENV["COSMOSDB_KEY"],
    ENV["COSMOSDB_LOG_DATABASE_NAME"],
    ENV["COSMOSDB_LOG_CONTAINER_NAME"]
)
tagsHelper = TagsHelper(
    ENV["COSMOSDB_URL"],
    ENV["COSMOSDB_KEY"],
    ENV["COSMOSDB_TAGS_DATABASE_NAME"],
    ENV["COSMOSDB_TAGS_CONTAINER_NAME"]
)

# Comment these two lines out if using keys, set your API key in the OPENAI_API_KEY environment variable instead
# openai.api_type = "azure_ad"
# openai_token = azure_credential.get_token("https://cognitiveservices.azure.com/.default")
openai.api_key = ENV["AZURE_OPENAI_SERVICE_KEY"]

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

## Temp fix for issue https://github.com/Azure/azure-sdk-for-python/issues/34337.
## Remove this if/else once the issue is fixed in the SDK.
if ENV["AZURE_OPENAI_DOMAIN"].endswith(".us"):
    model_name = ENV["AZURE_OPENAI_CHATGPT_MODEL_NAME"]
    model_version = ENV["AZURE_OPENAI_CHATGPT_MODEL_VERSION"]
    embedding_model_name = ENV["AZURE_OPENAI_EMBEDDINGS_MODEL_NAME"]
    embedding_model_version = ENV["AZURE_OPENAI_EMBEDDINGS_VERSION"]
else:
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
        r = await impl.run(json_body.get("history", []), json_body.get("overrides", {}))

        # To fix citation bug,below code is added.aparmar
        return {
                "data_points": r["data_points"],
                "answer": r["answer"],
                "thoughts": r["thoughts"],
                "citation_lookup": r["citation_lookup"],
            }

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
    Get the status of all file uploads in the last N hours.

    Parameters:
    - request: The HTTP request object.

    Returns:
    - results: The status of all file uploads in the specified timeframe.
    """
    json_body = await request.json()
    timeframe = json_body.get("timeframe")
    state = json_body.get("state")
    try:
        results = statusLog.read_files_status_by_timeframe(timeframe, State[state])
    except Exception as ex:
        log.exception("Exception in /getalluploadstatus")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

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

# Return AZURE_OPENAI_CHATGPT_DEPLOYMENT
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

# Return AZURE_OPENAI_CHATGPT_DEPLOYMENT
@app.get("/getWarningBanner")
async def get_warning_banner():
    """Get the warning banner text"""
    response ={
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
        log.exception("Exception in /getalluploadstatus")
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
        results = tagsHelper.get_all_tags()
    except Exception as ex:
        log.exception("Exception in /getalltags")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return results

@app.post("/retryFile")
async def retryFile(request: Request):

    json_body = await request.json()
    filePath = json_body.get("filePath")
    
    try:

        file_path_parsed = filePath.replace(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"] + "/", "")
        blob = blob_client.get_blob_client(ENV["AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"], file_path_parsed)  

        if blob.exists():
            raw_file = blob.download_blob().readall()

            # Overwrite the existing blob with new data
            blob.upload_blob(raw_file, overwrite=True) 

    except Exception as ex:
        logging.exception("Exception in /retryFile")
        raise HTTPException(status_code=500, detail=str(ex)) from ex
    return {"status": 200}


app.mount("/", StaticFiles(directory="static"), name="static")

if __name__ == "__main__":
    log.info("IA WebApp Starting Up...")
