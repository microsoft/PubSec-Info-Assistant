# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

""" Library of code for status logs reused across various calling features """
import os
from datetime import datetime, timedelta
import base64
from enum import Enum
import logging
from pymongo import MongoClient, ASCENDING
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
    """ Class for logging status of various processes to MongoDB"""

    def __init__(self, mongo_uri, database_name, collection_name):
        """ Constructor function """
        self.mongo_uri = mongo_uri
        self.database_name = database_name
        self.collection_name = collection_name
        self.client = MongoClient(self.mongo_uri)
        self.database = self.client[self.database_name]
        self.collection = self.database[self.collection_name]
        self._log_document = {}

        # Ensure indexes
        self.collection.create_index([("id", ASCENDING)], unique=True)

    def encode_document_id(self, document_id):
        """ encode a path/file name to remove unsafe chars for a MongoDB id """
        safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
        return safe_id

    def read_file_status(self, file_id: str, status_query_level: StatusQueryLevel = StatusQueryLevel.CONCISE):
        """ 
        Function to issue a query and return resulting single doc        
        args
            status_query_level - the StatusQueryLevel value representing concise 
            or verbose status updates to be included
            file_id - if you wish to return a single document by its path     
        """
        query = {"id": self.encode_document_id(file_id)}
        items = list(self.collection.find(query))

        # Now we have the document, remove the status updates that are
        # considered 'non-verbose' if required
        if status_query_level == StatusQueryLevel.CONCISE:
            for item in items:
                # Filter out status updates that have status_classification == "debug"
                item['status_updates'] = [update for update in item['status_updates']
                                          if update['status_classification'] != 'Debug']

        return items

    def read_file_state(self, file_id: str):
        """ 
        Function to issue a query and return state of a single doc        
        args
            file_id - if you wish to return a single document by its path     
        """
        query = {"id": self.encode_document_id(file_id)}
        item = self.collection.find_one(query, {"state": 1})
        return State(item['state'])

    def read_files_status_by_timeframe(self, within_n_hours: int, state: State = State.ALL, folder_path: str = 'All', tag: str = 'All', container: str = 'upload'):
        """ 
        Function to issue a query and return resulting docs          
        args
            within_n_hours - integer representing from how many minutes ago to return docs for
        """
        query = {}
        if within_n_hours != -1:
            from_time = datetime.utcnow() - timedelta(hours=within_n_hours)
            query["start_timestamp"] = {"$gt": from_time}

        if state != State.ALL:
            query["state"] = state.value

        if tag != "All":
            query["tags"] = tag

        path_prefix = container + '/'
        if folder_path == 'Root':
            query["file_path"] = {"$regex": f"^{path_prefix}"}
        else:
            query["file_path"] = {"$regex": f"^{path_prefix + folder_path}"}

        items = list(self.collection.find(query).sort("state_timestamp", -1))
        return items

    def upsert_document(self, document_path, status, status_classification: StatusClassification, state=State.PROCESSING, fresh_start=False):
        """ Function to upsert a status item for a specified id """
        base_name = os.path.basename(document_path)
        document_id = self.encode_document_id(document_path)

        # add status to standard logger
        logging.info("%s DocumentID - %s", status, document_id)

        # If this event is the start of an upload, remove any existing status files for this path
        if fresh_start:
            self.collection.delete_one({"id": document_id})

        json_document = self.collection.find_one({"id": document_id}) or {}
        if json_document.get('state') != state.value:
            json_document['state'] = state.value
            json_document['state_timestamp'] = datetime.now()

        json_document['id'] = document_id
        json_document['file_name'] = base_name
        json_document['status_updates'] = json_document.get('status_updates', [])
        json_document['status_updates'].append({
            "status": status,
            "status_classification": status_classification.value,
            "timestamp": datetime.now()
        })

        self.collection.update_one({"id": document_id}, {"$set": json_document}, upsert=True)
        self._log_document[document_id] = json_document

    def delete_status(self, item_id):
        """ Function to delete a status item by its id """
        self.collection.delete_one({"id": item_id})
