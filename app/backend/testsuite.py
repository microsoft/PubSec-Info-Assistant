import json
import re
import pytest
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
import os
from fastapi.testclient import TestClient
from dotenv import load_dotenv

dir = current_working_directory = os.getcwd()
# We're running from MAKE file, so we need to change directory to app/backend
if ("/app/backend" not in dir):
    os.chdir(f'{dir}/app/backend')

load_dotenv(dotenv_path=f'../../scripts/environments/infrastructure.debug.env')

from app import app
client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200

# Web API Validation for Microsoft CEO
def test_web_chat_api():
    response = client.post("/chat", json={
        "history":[{"user":"Who is the CEO of Microsoft?"}],
        "approach":4,
        "overrides":{
            "semantic_ranker": True,
            "semantic_captions": False,
            "top":5,
            "suggest_followup_questions":False,
            "user_persona":"analyst",
            "system_persona":"an Assistant",
            "ai_persona":"",
            "response_length":2048,
            "response_temp":0.6,
            "selected_folders":"All",
            "selected_tags":""},
        "citation_lookup":{},
        "thought_chain":{}})
    assert response.status_code == 200
    content = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    assert "Satya" in content
    
# Work API Validation for Microsoft CEO
def test_work_chat_api():
    response = client.post("/chat", json={
        "history":[{"user":"who is the CEO of Microsoft?"}],
        "approach":1,
        "overrides":{
            "semantic_ranker":True,
            "semantic_captions":False,
            "top":5,
            "suggest_followup_questions":False,
            "user_persona":"analyst",
            "system_persona":"an Assistant",
            "ai_persona":"",
            "response_length":2048,
            "response_temp":0.6,
            "selected_folders":"All",
            "selected_tags":""},
        "citation_lookup":{},
        "thought_chain":{}})
    assert response.status_code == 200
    content = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    assert "Satya" in content or "I am not sure." in content

# Search work, then compare with web API Validation for Microsoft CEO
def test_web_compare_work_chat_api():
    response = client.post("/chat", json={
        "history":[{"user":"who is the CEO of Microsoft?"}],
        "approach":1,
        "overrides":{
            "semantic_ranker":True,
            "semantic_captions":False,
            "top":5,
            "suggest_followup_questions":False,
            "user_persona":"analyst",
            "system_persona":"an Assistant",
            "ai_persona":"",
            "response_length":2048,
            "response_temp":0.6,
            "selected_folders":"All",
            "selected_tags":""},
        "citation_lookup":{},
        "thought_chain":{}})
    assert response.status_code == 200
    content = ""
    work_citation_lookup = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "work_citation_lookup" in eventJson and eventJson["work_citation_lookup"] != None:
            work_citation_lookup = eventJson["work_citation_lookup"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    payload = {"history":[{"user":"who is the CEO of Microsoft?",
                 "bot":content},
                {"user":"who is the CEO of Microsoft?"}],
     "approach":5,
     "overrides":{
                  "semantic_ranker":True,
                  "semantic_captions":False,
                  "top":5,
                  "suggest_followup_questions":False,
                  "user_persona":"analyst",
                  "system_persona":"an Assistant",
                  "ai_persona":"",
                  "response_length":2048,
                  "response_temp":0.6,
                  "selected_folders":"All",
                  "selected_tags":""},
     "citation_lookup": work_citation_lookup,
     "thought_chain":{"work_response": content}
     }
    
    response = client.post("/chat", json=payload)
    
    assert response.status_code == 200
    content = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    assert "Satya" in content or "I am not sure." in content


# Search web, then compare with work API Validation for Microsoft CEO
def test_work_compare_web_chat_api():
    response = client.post("/chat", json={
        "history":[{"user":"who is the CEO of Microsoft?"}],
        "approach":4,
        "overrides":{
            "semantic_ranker":True,
            "semantic_captions":False,
            "top":5,
            "suggest_followup_questions":False,
            "user_persona":"analyst",
            "system_persona":"an Assistant",
            "ai_persona":"",
            "response_length":2048,
            "response_temp":0.6,
            "selected_folders":"All",
            "selected_tags":""},
        "citation_lookup":{},
        "thought_chain":{}})
    assert response.status_code == 200
    content = ""
    web_citation_lookup = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "web_citation_lookup" in eventJson and eventJson["web_citation_lookup"] != None:
            web_citation_lookup = eventJson["web_citation_lookup"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    payload = {"history":[{"user":"who is the CEO of Microsoft?",
                 "bot":content},
                {"user":"who is the CEO of Microsoft?"}],
     "approach":6,
     "overrides":{
                  "semantic_ranker":True,
                  "semantic_captions":False,
                  "top":5,
                  "suggest_followup_questions":False,
                  "user_persona":"analyst",
                  "system_persona":"an Assistant",
                  "ai_persona":"",
                  "response_length":2048,
                  "response_temp":0.6,
                  "selected_folders":"All",
                  "selected_tags":""},
     "citation_lookup": web_citation_lookup,
     "thought_chain":{"web_response": content}
     }
    
    response = client.post("/chat", json=payload)
    
    assert response.status_code == 200
    content = ""
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "error" in eventJson and eventJson["error"] != None:
            content += eventJson["error"]
            
    assert "Satya" in content or "I am not sure." in content


def test_get_blob_client_url():
    response = client.get("/getblobclienturl")
    assert response.status_code == 200
    assert "blob.core.windows.net" in response.json()["url"]

def test_get_all_upload_status():
    response = client.post("/getalluploadstatus", json={
        "timeframe":4,
        "state":"ALL",
        "folder":"Root",
        "tag":"All"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_get_folders():
    response = client.post("/getfolders")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_get_tags():
    response = client.post("/gettags")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    

def test_get_hint():
    
    response = client.get("/getHint", params={"question": "What is 2+2?"})
    assert response.status_code == 200
    assert "add" in response.json().lower() or "addition" in response.json().lower()


def test_post_td():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post("/posttd", files={"csv": file})
        assert response.status_code == 200

def test_process_td_agent_response():
    response = client.get("/process_td_agent_response", params={"question": "How many rows are there in this file?"})
    assert response.status_code == 200
    assert "200" in response.json()

def test_process_agent_response():
    response = client.get("/process_agent_response", params={"question": "What is 2+2?"})
    assert response.status_code == 200
    assert "4" in response.json()

def test_get_info_data():
    response = client.get("/getInfoData")
    assert response.status_code == 200
    expected_response = {
        "AZURE_OPENAI_CHATGPT_DEPLOYMENT": "deployment_value",
        "AZURE_OPENAI_MODEL_NAME": "model_name_value",
        "AZURE_OPENAI_MODEL_VERSION": "model_version_value",
        "AZURE_OPENAI_SERVICE": "openai_service_value",
        "AZURE_SEARCH_SERVICE": "search_service_value",
        "AZURE_SEARCH_INDEX": "search_index_value",
        "TARGET_LANGUAGE": "en",
        "USE_AZURE_OPENAI_EMBEDDINGS": "true",
        "EMBEDDINGS_DEPLOYMENT": "embedding_deployment_value",
        "EMBEDDINGS_MODEL_NAME": "embedding_model_name_value",
        "EMBEDDINGS_MODEL_VERSION": "embedding_model_version_value",
    }
    assert response.json().keys() == expected_response.keys()
    

def test_get_warning_banner():
    response = client.get("/getWarningBanner")
    assert response.status_code == 200
    assert response.json() == {"WARNING_BANNER_TEXT": os.getenv("CHAT_WARNING_BANNER_TEXT")}

def test_get_max_csv_file_size():
    response = client.get("/getMaxCSVFileSize")
    assert response.status_code == 200
    assert response.json() == {"MAX_CSV_FILE_SIZE": os.getenv("MAX_CSV_FILE_SIZE")}

def test_get_application_title():
    response = client.get("/getApplicationTitle")
    assert response.status_code == 200
    assert response.json() == {"APPLICATION_TITLE": os.getenv("APPLICATION_TITLE")}

def test_get_all_tags():
    response = client.get("/getalltags")
    assert response.status_code == 200
    assert isinstance(response.json(), str)

def test_get_feature_flags():
    response = client.get("/getFeatureFlags")
    assert response.status_code == 200
    
    expected_response = {
        "ENABLE_WEB_CHAT": os.getenv("ENABLE_WEB_CHAT") == "true",
        "ENABLE_UNGROUNDED_CHAT": os.getenv("ENABLE_UNGROUNDED_CHAT") == "true",
        "ENABLE_MATH_ASSISTANT": os.getenv("ENABLE_MATH_ASSISTANT") == "true",
        "ENABLE_TABULAR_DATA_ASSISTANT": os.getenv("ENABLE_TABULAR_DATA_ASSISTANT") == "true",
        "ENABLE_MULTIMEDIA": os.getenv("ENABLE_MULTIMEDIA") == "true",
    }

    assert response.json() == expected_response

def test_upload_blob():
    account_name = os.getenv("AZURE_BLOB_STORAGE_ACCOUNT")
    account_key = os.getenv("AZURE_BLOB_STORAGE_KEY")
    container_name = os.getenv("AZURE_BLOB_STORAGE_UPLOAD_CONTAINER")
    blob_service_client = BlobServiceClient(account_url=f"https://{account_name}.blob.core.windows.net", credential=account_key)

    # Create a container client
    container_client = blob_service_client.get_container_client(container_name)

    # Path to the local file you want to upload
    local_file_path = "test_data/parts_inventory.csv"
    blob_name = "parts_inventory.csv"

    # Create a BlobClient
    blob_client = container_client.get_blob_client(blob_name)

    # Upload the file
    with open(local_file_path, "rb") as data:
        blob_client.upload_blob(data, overwrite=True)

def test_log_status():
    response = client.post("/logstatus", json={
        "path": "upload/parts_inventory.csv",
        "status": "File uploaded from test suite to Azure Blob Storage",
        "status_classification": "Info",
        "state": "Uploaded"
    })
    assert response.status_code == 200
    
def test_resubmit_item():
    response = client.post("/resubmitItems", json={"path": "/parts_inventory.csv"})
    assert response.status_code == 200
    assert response.json() == True

def test_delete_item():
    response = client.post("/deleteItems", json={"path": "/parts_inventory.csv"})
    assert response.status_code == 200
    assert response.json() == True


# This test requires some amount of data to be present and processed in IA
# It is commented out because processing the data takes time and the test will fail if the data is not processed
# Change the question to a valid question that will produce citations if you want to run this test
'''
def test_get_citation_obj():
    question = "Who is the CEO of Microsoft?"
    response = client.post("/chat", json={
        "history":[{"user": question}],
        "approach":1,
        "overrides":{
            "semantic_ranker": True,
            "semantic_captions": False,
            "top":5,
            "suggest_followup_questions":False,
            "user_persona":"analyst",
            "system_persona":"an Assistant",
            "ai_persona":"",
            "response_length":2048,
            "response_temp":0.6,
            "selected_folders":"All",
            "selected_tags":""},
        "citation_lookup":{},
        "thought_chain":{}})
    
    assert response.status_code == 200
    content = ""
    work_citation_lookup = {}
    for line in response.iter_lines():
        eventJson = json.loads(line)
        if "content" in eventJson and eventJson["content"] != None:
            content += eventJson["content"]
        elif "work_citation_lookup" in eventJson and eventJson["work_citation_lookup"] != None:
            work_citation_lookup = eventJson["work_citation_lookup"]
            
    # Define the regex pattern
    pattern = r'\[(File[0-9])\]'
    
    # Search for the first match
    match = re.search(pattern, content)
    
    # If a match is found, make a call to get citation object
    if match:
        response = client.post("/getcitation", json={"citation": work_citation_lookup[match.group(1)]})
        assert response.status_code == 200
    else:
        pytest.fail("No citation was found in work response. Unable to make a call to get citation object.")
'''