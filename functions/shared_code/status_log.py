# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

""" Library of code for status logs reused across various calling features """
import os
from datetime import datetime, timedelta
import base64
from enum import Enum
import logging
from azure.cosmos import CosmosClient, PartitionKey, exceptions
import traceback, sys

class State(Enum):
    """ Enum for state of a process """
    PROCESSING = "Processing"
    INDEXING = "Indexing"
    SKIPPED = "Skipped"
    QUEUED = "Queued"
    COMPLETE = "Complete"
    ERROR = "Error"
    THROTTLED = "Throttled"
    UPLOADED = "Uploaded"
    DELETED = "Deleted"
    DELETING = "Deleting"
    ALL = "All"

class StatusClassification(Enum):
    """ Enum for classification of a status message """
    DEBUG = "Debug"
    INFO = "Info"
    ERROR = "Error"

class StatusQueryLevel(Enum):
    """ Enum for level of detail of a status query """
    CONCISE = "Concise"
    VERBOSE = "Verbose"

class StatusLog:
    """ Class for logging status of various processes to Cosmos DB"""

    def __init__(self, url, azure_credential, database_name, container_name):
        """ Constructor function """
        self._url = url
        self.azure_credential = azure_credential
        self._database_name = database_name
        self._container_name = container_name
        self.cosmos_client = CosmosClient(url=self._url, credential=self.azure_credential, consistency_level='Session')
        self._log_document = {}

        # Select a database (will create it if it doesn't exist)
        self.database = self.cosmos_client.get_database_client(self._database_name)
        if self._database_name not in [db['id'] for db in self.cosmos_client.list_databases()]:
            self.database = self.cosmos_client.create_database(self._database_name)

        # Select a container (will create it if it doesn't exist)
        self.container = self.database.get_container_client(self._container_name)
        if self._container_name not in [container['id'] for container
                                        in self.database.list_containers()]:
            self.container = self.database.create_container(id=self._container_name,
                partition_key=PartitionKey(path="/file_name"))

    def encode_document_id(self, document_id):
        """ encode a path/file name to remove unsafe chars for a cosmos db id """
        safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
        return safe_id

    def read_file_status(self,
                       file_id: str,
                       status_query_level: StatusQueryLevel = StatusQueryLevel.CONCISE
                       ):
        """ 
        Function to issue a query and return resulting single doc        
        args
            status_query_level - the StatusQueryLevel value representing concise 
            or verbose status updates to be included
            file_id - if you wish to return a single document by its path     
        """
        query_string = f"SELECT * FROM c WHERE c.id = '{self.encode_document_id(file_id)}'"

        items = list(self.container.query_items(
            query=query_string,
            enable_cross_partition_query=True
        ))

        # Now we have the document, remove the status updates that are
        # considered 'non-verbose' if required
        if status_query_level == StatusQueryLevel.CONCISE:
            for item in items:
                # Filter out status updates that have status_classification == "debug"
                item['status_updates'] = [update for update in item['status_updates']
                                          if update['status_classification'] != 'Debug']

        return items


    def read_file_state(self,
                       file_id: str
                       ):
        """ 
        Function to issue a query and return state of a single doc        
        args
            file_id - if you wish to return a single document by its path     
        """
        query_string = f"SELECT c.state FROM c WHERE c.id = '{self.encode_document_id(file_id)}'"

        items = list(self.container.query_items(
            query=query_string,
            enable_cross_partition_query=True
        ))

        return State(items[0]['state'])


    def read_files_status_by_timeframe(self, 
                       within_n_hours: int,
                       state: State = State.ALL,
                       folder_path: str = 'All',
                       tag: str = 'All',
                       container: str = 'upload'
                       ):
        """ 
        Function to issue a query and return resulting docs          
        args
            within_n_hours - integer representing from how many minutes ago to return docs for
        """

        query_string = "SELECT c.id,  c.file_path, c.file_name, c.state, \
            c.start_timestamp, c.state_description, c.state_timestamp, c.status_updates, \
            c.tags FROM c"

        conditions = []    
        if within_n_hours != -1:
            from_time = datetime.utcnow() - timedelta(hours=within_n_hours)
            from_time_string = str(from_time.strftime('%Y-%m-%d %H:%M:%S'))
            conditions.append(f"c.start_timestamp > '{from_time_string}'")

        if state != State.ALL:
            conditions.append(f"c.state = '{state.value}'")
            
            
        #********************************************************
        # add a query clause to query the tags arays to only return
        # docs that have the specified tag
        #********************************************************
        if tag != "All":
            conditions.append(f"ARRAY_CONTAINS(c.tags, '{tag}')")
            
        path_prefix = container + '/'
        if folder_path == 'Root':
            conditions.append(f"STARTSWITH(c.file_path, '{path_prefix}')")
        else:
            conditions.append(f"STARTSWITH(c.file_path, '{path_prefix + folder_path}')")

        if conditions:
            query_string += " WHERE " + " AND ".join(conditions)

        query_string += " ORDER BY c.state_timestamp DESC"

        items = list(self.container.query_items(
            query=query_string,
            enable_cross_partition_query=True
        ))

        return items

    def upsert_document(self, document_path, status, status_classification: StatusClassification,
                        state=State.PROCESSING, fresh_start=False):
        """ Function to upsert a status item for a specified id """
        base_name = os.path.basename(document_path)
        document_id = self.encode_document_id(document_path)

        # add status to standard logger
        logging.info("%s DocumentID - %s", status, document_id)

        # If this event is the start of an upload, remove any existing status files for this path
        if fresh_start:
            try:
                self.container.delete_item(item=document_id, partition_key=base_name)
            except exceptions.CosmosResourceNotFoundError:
                pass

        json_document = ""
        try:
            # if the document exists and if this is the first call to the function from the parent,
            # then retrieve the stored document from cosmos, otherwise, use the log stored in self
            if self._log_document.get(document_id, "") == "":
                json_document = self.container.read_item(item=document_id, partition_key=base_name)
            else:
                json_document = self._log_document[document_id]

            if json_document['state'] != state.value:
                json_document['state'] = state.value
                json_document['state_timestamp'] = str(datetime
                                                        .now()
                                                        .strftime('%Y-%m-%d %H:%M:%S'))

            # Update state description with latest status
            json_document['state_description'] = status
            # Append a new item to the array
            status_updates = json_document["status_updates"]
            new_item = {
                "status": status,
                "status_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                "status_classification": str(status_classification.value)
            }

            if status_classification == StatusClassification.ERROR:
                new_item["stack_trace"] = self.get_stack_trace()
            status_updates.append(new_item)

        except exceptions.CosmosResourceNotFoundError:
            if state != State.DELETED:
                # this is a valid new document
                json_document = {
                    "id": document_id,
                    "file_path": document_path,
                    "file_name": base_name,
                    "state": str(state.value),
                    "start_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                    "state_description": status,
                    "state_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                    "status_updates": [
                        {
                            "status": status,
                            "status_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                            "status_classification": str(status_classification.value)
                        }
                    ]
                }
            elif state == State.DELETED:
                # the status file was previously deleted. Do nothing.
                logging.debug("No record found for deleted document %s. Nothing to do.",
                              document_path)
        except Exception as err:
            # log the exception with stack trace to the status log
            logging.error("Unexpected exception upserting document %s", str(err))
            json_document = {
                "id": document_id,
                "file_path": document_path,
                "file_name": base_name,
                "state": str(state.value),
                "start_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                "state_description": status,
                "state_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                "status_updates": [
                    {
                        "status": status,
                        "status_timestamp": str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                        "status_classification": str(status_classification.value),
                        "stack_trace": self.get_stack_trace() if not fresh_start else None
                    }
                ]
            }

        #self.container.upsert_item(body=json_document)
        self._log_document[document_id] = json_document

    def update_document_state(self, document_path, status, state=State.PROCESSING):
        """Updates the state of the document in the storage"""
        try:
            document_id = self.encode_document_id(document_path)
            logging.info("%sDocumentID - %s", status, document_id)
            if self._log_document.get(document_id, "") != "":
                json_document = self._log_document[document_id]
                json_document['state'] = state.value
                json_document['state_description'] = status
                json_document['state_timestamp'] = str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                self.save_document(document_path)
                self._log_document[document_id] = json_document
            else:
                logging.warning("Document with ID %s not found.", document_id)
        except Exception as err:
            logging.error("An error occurred while updating the document state: %s", str(err))
            
    def update_document_tags(self, document_path, tags_list):
        """ Upserts document tags into the database """
        try:       
            document_id = self.encode_document_id(document_path)
             # retrieve the stored document from cosmos
            base_name = os.path.basename(document_path)
            json_document = self.container.read_item(item=document_id, partition_key=base_name)
            json_document['tags'] = tags_list
            self._log_document[document_id] = json_document
            self.save_document(document_path)

        except Exception as err:
            logging.error("An error occurred while updating the document state: %s", str(err))

    def save_document(self, document_path):
        """Saves the document in the storage"""
        document_id = self.encode_document_id(document_path)
        if self._log_document[document_id] != "":
            self.container.upsert_item(body=self._log_document[document_id])
        else:
            logging.debug("no update to be made for %s, skipping.", document_path)
        self._log_document[document_id] = ""

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
            stackstr += '  ' + traceback.format_exc().lstrip()
        return stackstr

    def get_all_tags(self):
        """ Returns all tags in the database """
        query = "SELECT DISTINCT VALUE t FROM c JOIN t IN c.tags"
        tag_array = self.container.query_items(query=query, enable_cross_partition_query=True)
        return ",".join(tag_array)
    
    def delete_doc(self, doc: str) -> None:
        '''Deletes doc for a file paths'''
        doc_id = self.encode_document_id(f"upload/{doc}")
        file_path = f"upload/{doc}"
        logging.debug("deleting tags item for doc %s \n \t with ID %s", doc, doc_id)
        try:
            self.container.delete_item(item=doc_id, partition_key=file_path)
            logging.info("deleted tags for document path %s", file_path)
        except exceptions.CosmosResourceNotFoundError:
            logging.info("Tag entry for %s already deleted", file_path)