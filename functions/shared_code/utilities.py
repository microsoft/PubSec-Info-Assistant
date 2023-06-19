# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from datetime import datetime, timedelta

class Utilities:
    
    def __init__(self, 
                 azure_blob_storage_account,
                 azure_blob_drop_storage_container,
                 azure_blob_content_storage_container,
                 azure_blob_storage_key
                 ):
        self.azure_blob_storage_account = azure_blob_storage_account
        self.azure_blob_drop_storage_container = azure_blob_drop_storage_container
        self.azure_blob_content_storage_container = azure_blob_content_storage_container
        self.azure_blob_storage_key = azure_blob_storage_key        
    
    
    def  get_blob_and_sas(self, blob_path):
        """ Function to retrieve the uri and sas token for a given blob in azure storage"""
        logging.info("processing pdf " + blob_path)
        base_filename = os.path.basename(blob_path)

        # Get path and file name minus the root container
        separator = "/"
        file_path_w_name_no_cont = separator.join(
            blob_path.split(separator)[1:])

        # Gen SAS token
        sas_token = generate_blob_sas(
            account_name=self.azure_blob_storage_account,
            container_name=self.azure_blob_drop_storage_container,
            blob_name=file_path_w_name_no_cont,
            account_key=self.azure_blob_storage_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.utcnow() + timedelta(hours=1)
        )
        source_blob_path = f'https://{self.azure_blob_storage_account}.blob.core.windows.net/{blob_path}?{sas_token}'
        source_blob_path = source_blob_path.replace(" ", "%20")        
        logging.info(f"Path and SAS token for file in azure storage are now generated \n")
        return source_blob_path