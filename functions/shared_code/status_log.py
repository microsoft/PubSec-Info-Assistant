# Copyright (c) DataReason.
### Code for On-Premises Deployment.

""" Library of code for status logs reused across various calling features """
import os
from datetime import datetime, timedelta
import base64
from enum import Enum
import logging
import psycopg2
import json
import traceback
import sys

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
    """ Class for logging status of various processes to PostgreSQL """

    def __init__(self, postgres_url, database_name, table_name):
        """ Constructor function """
        self.connection = psycopg2.connect(postgres_url)
        self.database_name = database_name
        self.table_name = table_name
        self.create_table_if_not_exists()
        self._log_document = {}

    def create_table_if_not_exists(self):
        with self.connection.cursor() as cursor:
            cursor.execute(f"""
                CREATE TABLE IF NOT EXISTS {self.table_name} (
                    id TEXT PRIMARY KEY,
                    state_description TEXT,
                    classification TEXT,
                    state TEXT,
                    timestamp TIMESTAMP,
                    tags JSONB,
                    status_updates JSONB
                )
            """)
            self.connection.commit()

    def encode_document_id(self, document_id):
        """ Encode a path/file name to remove unsafe chars for a PostgreSQL id """
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
        query_string = f"SELECT * FROM {self.table_name} WHERE id = %s"
        with self.connection.cursor() as cursor:
            cursor.execute(query_string, (self.encode_document_id(file_id),))
            items = cursor.fetchall()

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
        query_string = f"SELECT state FROM {self.table_name} WHERE id = %s"
        with self.connection.cursor() as cursor:
            cursor.execute(query_string, (self.encode_document_id(file_id),))
            result = cursor.fetchone()
            return State(result[0]) if result else None

    def read_files_status_by_timeframe(self, within_n_hours: int, state: State = State.ALL, folder_path: str = 'All', tag: str = 'All', container: str = 'upload'):
        """ 
        Function to issue a query and return resulting docs 
        args
            within_n_hours - integer representing from how many minutes ago to return docs for
        """
        query_string = f"SELECT id, file_path, file_name, state, start_timestamp, state_description, state_timestamp, status_updates, tags FROM {self.table_name}"
        conditions = [] 
        if within_n_hours != -1:
            from_time = datetime.utcnow() - timedelta(hours=within_n_hours)
            from_time_string = str(from_time.strftime('%Y-%m-%d %H:%M:%S'))
            conditions.append(f"start_timestamp > '{from_time_string}'")

        if state != State.ALL:
            conditions.append(f"state = '{state.value}'")
            
        if tag != "All":
            conditions.append(f"tags @> '[\"{tag}\"]'")
            
        path_prefix = container + '/'
        if folder_path == 'Root':
            conditions.append(f"file_path LIKE '{path_prefix}%'")
        else:
            conditions.append(f"file_path LIKE '{path_prefix + folder_path}%'")

        if conditions:
            query_string += " WHERE " + " AND ".join(conditions)

        query_string += " ORDER BY state_timestamp DESC"

        with self.connection.cursor() as cursor:
            cursor.execute(query_string)
            items = cursor.fetchall()

        return items

    def upsert_document(self, document_path, status, status_classification: StatusClassification, state=State.PROCESSING, fresh_start=False):
        """ Function to upsert a status item for a specified id """
        base_name = os.path.basename(document_path)
        document_id = self.encode_document_id(document_path)
        timestamp = datetime.utcnow().isoformat()

        # Add status to standard logger
        logging.info("%s DocumentID - %s", status, document_id)

        # If this event is the start of an upload, remove any existing status files for this path
        if fresh_start:
            try:
                with self.connection.cursor() as cursor:
                    cursor.execute(f"DELETE FROM {self.table_name} WHERE id = %s", (document_id,))
                    self.connection.commit()
            except Exception as e:
                logging.error(f"Error deleting existing status file for {document_id}: {str(e)}")

        json_document = ""
        try:
            # If the document exists and if this is the first call to the function from the parent,
            # then retrieve the stored document from PostgreSQL, otherwise, use the log stored in self
            if self._log_document.get(document_id, "") == "":
                with self.connection.cursor() as cursor:
                    cursor.execute(f"SELECT * FROM {self.table_name} WHERE id = %s", (document_id,))
                    json_document = cursor.fetchone()
            else:
                json_document = self._log_document[document_id]

            if json_document['state'] != state.value:
                json_document['state'] = state.value
                json_document['state_timestamp'] = str(datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

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

        except Exception as e:
            if state != State.DELETED:
                # This is a valid new document
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
                # The status file was previously deleted. Do nothing.
                logging.debug("No record found for deleted document %s. Nothing to do.", document_path)
        except Exception as err:
            # Log the exception with stack trace to the status log
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

        self._log_document[document_id] = json_document

    def update_document_state(self, document_path, status, state=State.PROCESSING):
        """Updates the state of the document in the storage"""
                try:
            document_id = self.encode_document_id(document_path)
            logging.info("%s DocumentID - %s", status, document_id)
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
            # Retrieve the stored document from PostgreSQL
            with self.connection.cursor() as cursor:
                cursor.execute(f"SELECT * FROM {self.table_name} WHERE id = %s", (document_id,))
                json_document = cursor.fetchone()
            json_document['tags'] = tags_list
            self._log_document[document_id] = json_document
            self.save_document(document_path)
        except Exception as err:
            logging.error("An error occurred while updating the document tags: %s", str(err))

    def save_document(self, document_path):
        """Saves the document in the storage"""
        document_id = self.encode_document_id(document_path)
        if self._log_document[document_id] != "":
            with self.connection.cursor() as cursor:
                cursor.execute(f"""
                    INSERT INTO {self.table_name} (id, state_description, classification, state, timestamp, tags, status_updates)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (id) DO UPDATE
                    SET state_description = EXCLUDED.state_description,
                        classification = EXCLUDED.classification,
                        state = EXCLUDED.state,
                        timestamp = EXCLUDED.timestamp,
                        tags = EXCLUDED.tags,
                        status_updates = EXCLUDED.status_updates
                """, (
                    self._log_document[document_id]['id'],
                    self._log_document[document_id]['state_description'],
                    self._log_document[document_id]['classification'],
                    self._log_document[document_id]['state'],
                    self._log_document[document_id]['timestamp'],
                    json.dumps(self._log_document[document_id]['tags']),
                    json.dumps(self._log_document[document_id]['status_updates'])
                ))
                self.connection.commit()
        else:
            logging.debug("No update to be made for %s, skipping.", document_path)
        self._log_document[document_id] = ""

    def get_stack_trace(self):
        """ Returns the stack trace of the current exception"""
        exc = sys.exc_info()[0]
        stack = traceback.extract_stack()[:-1] # last one would be full_stack()
        if exc is not None: # i.e. an exception is present
            del stack[-1] # remove call of full_stack, the printed exception
                          # will contain the caught exception caller instead
        trc = 'Traceback (most recent call last):\n'
        stackstr = trc + ''.join(traceback.format_list(stack))
        if exc is not None:
            stackstr += ' ' + traceback.format_exc().lstrip()
        return stackstr

    def get_all_tags(self):
        """ Returns all tags in the database """
        query = f"SELECT DISTINCT jsonb_array_elements_text(tags) FROM {self.table_name}"
        with self.connection.cursor() as cursor:
            cursor.execute(query)
            tag_array = cursor.fetchall()
        return ",".join([tag[0] for tag in tag_array])

    def delete_doc(self, doc: str) -> None:
        """Deletes doc for a file path"""
        doc_id = self.encode_document_id(f"upload/{doc}")
        logging.debug("Deleting tags item for doc %s with ID %s", doc, doc_id)
        try:
            with self.connection.cursor() as cursor:
                cursor.execute(f"DELETE FROM {self.table_name} WHERE id = %s", (doc_id,))
                self.connection.commit()
            logging.info("Deleted tags for document path %s", doc)
        except Exception as e:
            logging.error("Error deleting document %s: %s", doc, str(e))

#Key Changes:
#PostgreSQL: Replaced Azure Cosmos DB with PostgreSQL for logging and status tracking.
#Table Creation: Added a method to create the table if it does not exist.
#Upsert Logic: Adjusted the upsert logic to work with PostgreSQL.
#Error Handling: Adjusted error handling to work with PostgreSQL.
#Query Adjustments: Modified the query logic to work with PostgreSQL.
#Stack Trace: Added method to get the stack trace of the current exception.	