# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import os
import logging
import urllib.parse
from datetime import datetime, timedelta
from minio import Minio
from minio.error import S3Error

class UtilitiesHelper:
    """ Helper class for utility functions"""

    def __init__(self, minio_endpoint, minio_access_key, minio_secret_key, minio_bucket_name):
        self.minio_client = Minio(
            minio_endpoint,
            access_key=minio_access_key,
            secret_key=minio_secret_key,
            secure=False
        )
        self.minio_bucket_name = minio_bucket_name

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

    def get_blob_and_sas(self, blob_path):
        """ Function to retrieve the uri and sas token for a given blob in MinIO storage"""
        # Get path and file name minus the root container
        separator = "/"
        file_path_w_name_no_cont = separator.join(blob_path.split(separator)[1:])
        container_name = separator.join(blob_path.split(separator)[0:1])

        try:
            # Generate a presigned URL for the object
            presigned_url = self.minio_client.presigned_get_object(self.minio_bucket_name, file_path_w_name_no_cont, expires=timedelta(hours=1))
            logging.info("Path and presigned URL for file in MinIO storage are now generated \n")
            return presigned_url
        except S3Error as err:
            logging.error(f"Error generating presigned URL: {err}")
            return None

#Changes Made:
#1.MinIO Client Initialization: Replaced Azure Blob Storage client with MinIO client.
#2.Presigned URL Generation: Adapted the get_blob_and_sas method to generate a presigned URL using MinIO.
#3.Removed Azure-specific Imports: Removed Azure-specific imports and replaced them with MinIO imports.