""" Library of code functions that are reused across various calling features """
import os
from datetime import datetime
import base64
from azure.cosmos import CosmosClient, PartitionKey


def encode_document_id(document_id):
    """ encode a path/file name to remove unsafe chars for a cosmos db id """
    safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
    return safe_id


def upsert_document(url, key, database_name, container_name, document_path, status):
    """ Function to upsert a status item for a specified id """
    cosmos_client = CosmosClient(url=url, credential=key)

    # Select a database (will create it if it doesn't exist)
    database = cosmos_client.get_database_client(database_name)
    if database_name not in [db['id'] for db in cosmos_client.list_databases()]:
        database = cosmos_client.create_database(database_name)

    # Select a container (will create it if it doesn't exist)
    container = database.get_container_client(container_name)
    if container_name not in [container['id'] for container in database.list_containers()]:
        container = database.create_container(id=container_name, 
            partition_key=PartitionKey(path="/file_name"))
        
    base_name = os.path.basename(document_path)
    document_id = encode_document_id(document_path)
    
    # If this event is the start of an upload, remove any existing status files for this path
    if status == "File Uploaded":
        container.delete_item(item=document_id, partition_key=base_name)

    json_document = ""
    try:
        # if the document exists then update it        
        json_document = container.read_item(item=document_id, partition_key=base_name)
        # json_document = json.loads(json_data)
        status_updates = json_document["StatusUpdates"]
        # Append a new item to the array
        new_item = {
            "status": status,
            "datetime": str(datetime.now())
        }
        status_updates.append(new_item)

    except Exception:
            json_document = {
                "id": document_id,
                "file_path": document_path,
                "file_name": base_name,
                "StatusUpdates": [
                    {
                        "status": status,
                        "datetime": str(datetime.now())
                    }
                ]
            }

    container.upsert_item(body=json_document)