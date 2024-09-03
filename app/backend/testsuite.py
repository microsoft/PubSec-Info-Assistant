import json
import re
import pytest
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
from azure.identity import DefaultAzureCredential
import os
from fastapi.testclient import TestClient
from dotenv import load_dotenv
import io

dir = current_working_directory = os.getcwd()
# We're running from MAKE file, so we need to change directory to app/backend
if ("/app/backend" not in dir):
    os.chdir(f'{dir}/app/backend')

load_dotenv(dotenv_path=f'../../scripts/environments/infrastructure.debug.env')

azure_credentials = DefaultAzureCredential()

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


def test_get_blob_client():
    response = client.get("/getblobclient")
    assert response.status_code == 200
    assert "blob.core.windows.net" in response.json()["client"].url

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
    }

    assert response.json() == expected_response

def test_upload_blob():
    storage_account_url=os.getenv("BLOB_STORAGE_ACCOUNT_ENDPOINT")
    container_name = os.getenv("AZURE_BLOB_STORAGE_UPLOAD_CONTAINER")
    blob_service_client = BlobServiceClient(account_url=storage_account_url, credential=azure_credentials)

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
        
    return blob_name 

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
  
def test_get_file():  
    blob_name = test_upload_blob()
      
    try:  
        file_path = blob_name  
        response = client.post("/get-file", json={"path": file_path})  
          
        assert response.status_code == 200  
        assert response.headers["Content-Disposition"] == f"inline; filename=parts_inventory.csv"  
        assert "text/csv" in response.headers["Content-Type"]  
    finally:  
        test_delete_item() 
    assert response.json() == True

def test_upload_file_one_tag():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "parts_inventory.csv", "tags": "test"}
        )
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}


def test_uploadfilenotagsnofolder():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "parts_inventory.csv", "tags": ""}
        )
        print(response.json())
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}

def test_uploadfiletags():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "parts_inventory.csv", "tags": "test,inventory"}
        )
        print(response.json())
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}
def test_uploadfilespecificfolder():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "Finance/parts_inventory.csv", "tags": "test"}
        )
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}
def test_uploadfilespecificfoldernested():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "Finance/new/parts_inventory.csv", "tags": "test"}
        )
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}

def test_upload_file_no_file():
    response = client.post(
        "/file",
        data={"file_path": "parts_inventory.csv", "tags": "test"}
    )
    assert response.status_code == 422  # Unprocessable Entity

def test_upload_file_large_file():
    file_content = b"a" * (10 * 1024 * 1024)  # 10 MB file
    file = io.BytesIO(file_content)
    file.name = "large_parts_inventory.csv"
    
    response = client.post(
        "/file",
        files={"file": (file.name, file, "text/csv")},
        data={"file_path": "large_parts_inventory.csv", "tags": "test"}
    )
    assert response.status_code == 200
    assert response.json() == {"message": "File 'large_parts_inventory.csv' uploaded successfully"}

def test_upload_file_missing_file_path():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"tags": "test"}
        )
        assert response.status_code == 422  # Unprocessable Entity
def test_upload_file_special_characters_in_file_path():
    with open("test_data/parts_inventory.csv", "rb") as file:
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "Finance/@new/parts_inventory.csv", "tags": "test"}
        )
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}

def test_upload_file_long_tags():
    with open("test_data/parts_inventory.csv", "rb") as file:
        long_tags = ",".join(["tag"] * 1000)  # Very long tags string
        response = client.post(
            "/file",
            files={"file": ("parts_inventory.csv", file, "text/csv")},
            data={"file_path": "parts_inventory.csv", "tags": long_tags}
        )
        assert response.status_code == 200
        assert response.json() == {"message": "File 'parts_inventory.csv' uploaded successfully"}
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