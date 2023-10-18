# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import logging
from datetime import datetime, timedelta
from azure.storage.blob import generate_blob_sas, BlobSasPermissions

class UtilitiesHelper:
    """ Helper class for utility functions"""
    def __init__(self,
                 azure_blob_storage_account,
                 azure_blob_storage_endpoint,
                 azure_blob_storage_key
                 ):
        self.azure_blob_storage_account = azure_blob_storage_account
        self.azure_blob_storage_endpoint = azure_blob_storage_endpoint
        self.azure_blob_storage_key = azure_blob_storage_key
        
    def get_filename_and_extension(self, path):
            """ Function to return the file name & type"""
            # Split the path into base and extension
            base_name = os.path.basename(path)
            segments = path.split("/")
            directory = "/".join(segments[1:-1]) + "/"
            if directory == "/":
                directory = ""
            file_name, file_extension = os.path.splitext(base_name)
            return file_name, file_extension, directory
    
    def  get_blob_and_sas(self, blob_path):
        """ Function to retrieve the uri and sas token for a given blob in azure storage"""

        # Get path and file name minus the root container
        separator = "/"
        file_path_w_name_no_cont = separator.join(
            blob_path.split(separator)[1:])
        
        container_name = separator.join(
            blob_path.split(separator)[0:1])

        # Gen SAS token
        sas_token = generate_blob_sas(
            account_name=self.azure_blob_storage_account,
            container_name=container_name,
            blob_name=file_path_w_name_no_cont,
            account_key=self.azure_blob_storage_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.utcnow() + timedelta(hours=1)
        )
        source_blob_path = f'{self.azure_blob_storage_endpoint}{blob_path}?{sas_token}'
        source_blob_path = source_blob_path.replace(" ", "%20")
        logging.info("Path and SAS token for file in azure storage are now generated \n")
        return source_blob_path