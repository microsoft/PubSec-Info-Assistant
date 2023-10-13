# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import mimetypes
import os
import json
import urllib.parse
from datetime import datetime, timedelta

import openai
from approaches.chatreadretrieveread import ChatReadRetrieveReadApproach
from azure.core.credentials import AzureKeyCredential
from azure.identity import DefaultAzureCredential
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from azure.search.documents import SearchClient
from azure.storage.blob import (
    AccountSasPermissions,
    BlobServiceClient,
    ResourceTypes,
    generate_account_sas,
)
from flask import Flask, jsonify, request
from shared_code.status_log import State, StatusClassification, StatusLog

# Replace these with your own values, either in environment variables or directly here
AZURE_BLOB_STORAGE_ACCOUNT = (
    os.environ.get("AZURE_BLOB_STORAGE_ACCOUNT") or "mystorageaccount"
)
AZURE_BLOB_STORAGE_ENDPOINT = os.environ.get("AZURE_BLOB_STORAGE_ENDPOINT") 
AZURE_BLOB_STORAGE_KEY = os.environ.get("AZURE_BLOB_STORAGE_KEY")
AZURE_BLOB_STORAGE_CONTAINER = (
    os.environ.get("AZURE_BLOB_STORAGE_CONTAINER") or "content"
)
AZURE_SEARCH_SERVICE = os.environ.get("AZURE_SEARCH_SERVICE") or "gptkb"
AZURE_SEARCH_SERVICE_ENDPOINT = os.environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
AZURE_SEARCH_SERVICE_KEY = os.environ.get("AZURE_SEARCH_SERVICE_KEY")
AZURE_SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX") or "gptkbindex"
AZURE_OPENAI_SERVICE = os.environ.get("AZURE_OPENAI_SERVICE") or "myopenai"
AZURE_OPENAI_RESOURCE_GROUP = os.environ.get("AZURE_OPENAI_RESOURCE_GROUP") or ""
AZURE_OPENAI_CHATGPT_DEPLOYMENT = (
    os.environ.get("AZURE_OPENAI_CHATGPT_DEPLOYMENT") or "chat"
)
AZURE_OPENAI_CHATGPT_MODEL_NAME = ( os.environ.get("AZURE_OPENAI_CHATGPT_MODEL_NAME") or "")
AZURE_OPENAI_CHATGPT_VERSION = ( os.environ.get("AZURE_OPENAI_CHATGPT_VERSION") or "")

AZURE_OPENAI_SERVICE_KEY = os.environ.get("AZURE_OPENAI_SERVICE_KEY")
AZURE_SUBSCRIPTION_ID = os.environ.get("AZURE_SUBSCRIPTION_ID")
str_to_bool = {'true': True, 'false': False}
IS_GOV_CLOUD_DEPLOYMENT = str_to_bool.get(os.environ.get("IS_GOV_CLOUD_DEPLOYMENT").lower()) or False
CHAT_WARNING_BANNER_TEXT = os.environ.get("CHAT_WARNING_BANNER_TEXT") or ""



KB_FIELDS_CONTENT = os.environ.get("KB_FIELDS_CONTENT") or "content"
KB_FIELDS_PAGENUMBER = os.environ.get("KB_FIELDS_PAGENUMBER") or "pages"
KB_FIELDS_SOURCEFILE = os.environ.get("KB_FIELDS_SOURCEFILE") or "file_uri"
KB_FIELDS_CHUNKFILE = os.environ.get("KB_FIELDS_CHUNKFILE") or "chunk_file"

COSMOSDB_URL = os.environ.get("COSMOSDB_URL")
COSMODB_KEY = os.environ.get("COSMOSDB_KEY")
COSMOSDB_DATABASE_NAME = os.environ.get("COSMOSDB_DATABASE_NAME") or "statusdb"
COSMOSDB_CONTAINER_NAME = os.environ.get("COSMOSDB_CONTAINER_NAME") or "statuscontainer"

QUERY_TERM_LANGUAGE = os.environ.get("QUERY_TERM_LANGUAGE") or "English"

TARGET_EMBEDDING_MODEL = os.environ.get("TARGET_EMBEDDING_MODEL") or "BAAI/bge-small-en-v1.5"
ENRICHMENT_APPSERVICE_NAME = os.environ.get("ENRICHMENT_APPSERVICE_NAME") or "enrichment"

# embedding_service_suffix = "xyoek"

# Use the current user identity to authenticate with Azure OpenAI, Cognitive Search and Blob Storage (no secrets needed,
# just use 'az login' locally, and managed identity when deployed on Azure). If you need to use keys, use separate AzureKeyCredential instances with the
# keys for each service
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
azure_credential = DefaultAzureCredential()
azure_search_key_credential = AzureKeyCredential(AZURE_SEARCH_SERVICE_KEY)

# Used by the OpenAI SDK
openai.api_type = "azure"
openai.api_base = f"https://{AZURE_OPENAI_SERVICE}.openai.azure.com"
openai.api_version = "2023-06-01-preview"

# Setup StatusLog to allow access to CosmosDB for logging
statusLog = StatusLog(
    COSMOSDB_URL, COSMODB_KEY, COSMOSDB_DATABASE_NAME, COSMOSDB_CONTAINER_NAME
)

# Comment these two lines out if using keys, set your API key in the OPENAI_API_KEY environment variable instead
# openai.api_type = "azure_ad"
# openai_token = azure_credential.get_token("https://cognitiveservices.azure.com/.default")
openai.api_key = AZURE_OPENAI_SERVICE_KEY

# Set up clients for Cognitive Search and Storage
search_client = SearchClient(
    endpoint=AZURE_SEARCH_SERVICE_ENDPOINT,
    index_name=AZURE_SEARCH_INDEX,
    credential=azure_search_key_credential,
)
blob_client = BlobServiceClient(
    account_url=AZURE_BLOB_STORAGE_ENDPOINT,
    credential=AZURE_BLOB_STORAGE_KEY,
)
blob_container = blob_client.get_container_client(AZURE_BLOB_STORAGE_CONTAINER)

model_name = ''
model_version = ''

if (IS_GOV_CLOUD_DEPLOYMENT):
    model_name = os.environ.get("AZURE_OPENAI_CHATGPT_MODEL_NAME")
    model_version = os.environ.get("AZURE_OPENAI_CHATGPT_MODEL_VERSION")
else:
    # Set up OpenAI management client
    openai_mgmt_client = CognitiveServicesManagementClient(
        credential=azure_credential,
        subscription_id=AZURE_SUBSCRIPTION_ID)

    deployment = openai_mgmt_client.deployments.get(
        resource_group_name=AZURE_OPENAI_RESOURCE_GROUP,
        account_name=AZURE_OPENAI_SERVICE,
        deployment_name=AZURE_OPENAI_CHATGPT_DEPLOYMENT)

    model_name = deployment.properties.model.name
    model_version = deployment.properties.model.version

chat_approaches = {
    "rrr": ChatReadRetrieveReadApproach(
        search_client,
        AZURE_OPENAI_SERVICE,
        AZURE_OPENAI_SERVICE_KEY,
        AZURE_OPENAI_CHATGPT_DEPLOYMENT,
        KB_FIELDS_SOURCEFILE,
        KB_FIELDS_CONTENT,
        KB_FIELDS_PAGENUMBER,
        KB_FIELDS_CHUNKFILE,
        AZURE_BLOB_STORAGE_CONTAINER,
        blob_client,
        QUERY_TERM_LANGUAGE,
        model_name,
        model_version,
        IS_GOV_CLOUD_DEPLOYMENT,
        TARGET_EMBEDDING_MODEL,
        ENRICHMENT_APPSERVICE_NAME
    )
}

app = Flask(__name__)


@app.route("/", defaults={"path": "index.html"})
@app.route("/<path:path>")
def static_file(path):
    """Serve static files from the 'static' directory"""
    return app.send_static_file(path)

@app.route("/chat", methods=["POST"])
def chat():
    """Chat with the bot using a given approach"""
    approach = request.json["approach"]
    try:
        impl = chat_approaches.get(approach)
        if not impl:
            return jsonify({"error": "unknown approach"}), 400
        r = impl.run(request.json["history"], request.json.get("overrides") or {})

        # return jsonify(r)
        # To fix citation bug,below code is added.aparmar
        return jsonify(
            {
                "data_points": r["data_points"],
                "answer": r["answer"],
                "thoughts": r["thoughts"],
                "citation_lookup": r["citation_lookup"],
            }
        )

    except Exception as ex:
        logging.exception("Exception in /chat")
        return jsonify({"error": str(ex)}), 500

@app.route("/getblobclienturl")
def get_blob_client_url():
    """Get a URL for a file in Blob Storage with SAS token"""
    sas_token = generate_account_sas(
        AZURE_BLOB_STORAGE_ACCOUNT,
        AZURE_BLOB_STORAGE_KEY,
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
    return jsonify({"url": f"{blob_client.url}?{sas_token}"})

@app.route("/getalluploadstatus", methods=["POST"])
def get_all_upload_status():
    """Get the status of all file uploads in the last N hours"""
    timeframe = request.json["timeframe"]
    state = request.json["state"]
    try:
        results = statusLog.read_files_status_by_timeframe(timeframe, State[state])
    except Exception as ex:
        logging.exception("Exception in /getalluploadstatus")
        return jsonify({"error": str(ex)}), 500
    return jsonify(results)

@app.route("/logstatus", methods=["POST"])
def logstatus():
    """Log the status of a file upload to CosmosDB"""
    try:
        path = request.json["path"]
        status = request.json["status"]
        status_classification = StatusClassification[request.json["status_classification"].upper()]
        state = State[request.json["state"].upper()]

        statusLog.upsert_document(document_path=path,
                                  status=status,
                                  status_classification=status_classification,
                                  state=state,
                                  fresh_start=True)
        statusLog.save_document(document_path=path)
        
    except Exception as ex:
        logging.exception("Exception in /logstatus")
        return jsonify({"error": str(ex)}), 500
    return jsonify({"status": 200})

# Return AZURE_OPENAI_CHATGPT_DEPLOYMENT
@app.route("/getInfoData")
def get_info_data():
    """Get the info data for the app"""
    response = jsonify(
        {
            "AZURE_OPENAI_CHATGPT_DEPLOYMENT": f"{AZURE_OPENAI_CHATGPT_DEPLOYMENT}",
            "AZURE_OPENAI_MODEL_NAME": f"{model_name}",
            "AZURE_OPENAI_MODEL_VERSION": f"{model_version}",
            "AZURE_OPENAI_SERVICE": f"{AZURE_OPENAI_SERVICE}",
            "AZURE_SEARCH_SERVICE": f"{AZURE_SEARCH_SERVICE}",
            "AZURE_SEARCH_INDEX": f"{AZURE_SEARCH_INDEX}",
            "TARGET_LANGUAGE": f"{QUERY_TERM_LANGUAGE}"
        })
    return response

# Return AZURE_OPENAI_CHATGPT_DEPLOYMENT
@app.route("/getWarningBanner")
def get_warning_banner():
    """Get the warning banner text"""
    response = jsonify(
        {
            "WARNING_BANNER_TEXT": f"{CHAT_WARNING_BANNER_TEXT}"
        })
    return response

@app.route("/getcitation", methods=["POST"])
def get_citation():
    """Get the citation for a given file"""
    citation = urllib.parse.unquote(request.json["citation"])
    try:
        blob = blob_container.get_blob_client(citation).download_blob()
        decoded_text = blob.readall().decode()
        results = jsonify(json.loads(decoded_text))
    except Exception as ex:
        logging.exception("Exception in /getalluploadstatus")
        return jsonify({"error": str(ex)}), 500
    return jsonify(results.json)

if __name__ == "__main__":
    app.run()
