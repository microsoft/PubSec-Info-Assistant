# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from azure.cosmos import CosmosClient, PartitionKey
import traceback, sys
import base64

class TagsHelper:
    """ Helper class for tag functions"""

    def __init__(self, url, key, database_name, container_name):
        """ Constructor function """
        self._url = url
        self._key = key
        self._database_name = database_name
        self._container_name = container_name
        self.cosmos_client = CosmosClient(url=self._url, credential=self._key)

        # Select a database (will create it if it doesn't exist)
        self.database = self.cosmos_client.get_database_client(self._database_name)
        if self._database_name not in [db['id'] for db in self.cosmos_client.list_databases()]:
            self.database = self.cosmos_client.create_database(self._database_name)

        # Select a container (will create it if it doesn't exist)
        self.container = self.database.get_container_client(self._container_name)
        if self._container_name not in [container['id'] for container
                                        in self.database.list_containers()]:
            self.container = self.database.create_container(id=self._container_name,
                partition_key=PartitionKey(path="/file_path"))

    def get_all_tags(self):
        """ Returns all tags in the database """
        query = "SELECT DISTINCT VALUE t FROM c JOIN t IN c.tags"
        tag_array = self.container.query_items(query=query, enable_cross_partition_query=True)
        return ",".join(tag_array)
    
    def upsert_document(self, document_path, tags_list):
        """ Upserts a document into the database """
        document_id = self.encode_document_id(document_path)
        document = {
            "id": document_id,
            "file_path": document_path,
            "tags": tags_list
        }
        self.container.upsert_item(document)

    def encode_document_id(self, document_id):
        """ encode a path/file name to remove unsafe chars for a cosmos db id """
        safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
        return safe_id
    
    def get_stack_trace(self):
        """ Returns the stack trace of the current exception"""
        exc = sys.exc_info()[0]
        stack = traceback.extract_stack()[:-1]  # last one would be full_stack()
        if exc is not None:  # i.e. an exception is present
            del stack[-1]       # remove call of full_stack, the printed exception
                                # will contain the caught exception caller instead
        trc = 'Traceback (most recent call last):\n'
        stackstr = trc + ''.join(traceback.format_list(stack))
        if exc is not None:
            stackstr += '  ' + traceback.format_exc().lstrip(trc)
        return stackstr