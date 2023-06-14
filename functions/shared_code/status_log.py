""" Library of code for status logs reused across various calling features """
import os
from datetime import datetime
import base64
from azure.cosmos import CosmosClient, PartitionKey, exceptions


class StatusLog:

    def __init__(self):
        self._url = None
        self._key = None
        self._database_name = None
        self._container_name = None

    @property
    def url(self):
        return self._url

    @url.setter
    def url(self, value):
        self._url = value
        
    @property
    def key(self):
        return self._key

    @key.setter
    def key(self, value):
        self._key = value
        
    @property
    def database_name(self):
        return self._database_name

    @database_name.setter
    def database_name(self, value):
        self._database_name = value
        
    @property
    def container_name(self):
        return self._container_name

    @container_name.setter
    def container_name(self, value):
        self._container_name = value


    def encode_document_id(self, document_id):
        """ encode a path/file name to remove unsafe chars for a cosmos db id """
        safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
        return safe_id


    def upsert_document(self, document_path, status, fresh_start=False):
        """ Function to upsert a status item for a specified id """
        cosmos_client = CosmosClient(url=self._url, credential=self._key)

        # Select a database (will create it if it doesn't exist)
        database = cosmos_client.get_database_client(self._database_name)
        if self._database_name not in [db['id'] for db in cosmos_client.list_databases()]:
            database = cosmos_client.create_database(self._database_name)

        # Select a container (will create it if it doesn't exist)
        container = database.get_container_client(self._container_name)
        if self._container_name not in [container['id'] for container in database.list_containers()]:
            container = database.create_container(id=self._container_name, 
                partition_key=PartitionKey(path="/file_name"))
            
        base_name = os.path.basename(document_path)
        document_id = self.encode_document_id(document_path)
        
        # If this event is the start of an upload, remove any existing status files for this path
        if fresh_start == True:
            try:
                container.delete_item(item=document_id, partition_key=base_name)
            except exceptions.CosmosResourceNotFoundError:
                pass

        json_document = ""
        try:
            # if the document exists then update it        
            json_document = container.read_item(item=document_id, partition_key=base_name)
            # json_document = json.loads(json_data)
            status_updates = json_document["StatusUpdates"]
            # Append a new item to the array
            new_item = {
                "status": status,
                "datetime": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
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
                            "datetime": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                        }
                    ]
                }

        container.upsert_item(body=json_document)