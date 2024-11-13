import os
import logging
import urllib.parse
from datetime import datetime, timedelta
from minio import Minio
from minio.error import S3Error

class UtilitiesHelper:
    """ Helper class for utility functions"""
    def __init__(self,
                 minio_url,
                 minio_access_key,
                 minio_secret_key):
        self.minio_url = minio_url
        self.minio_access_key = minio_access_key
        self.minio_secret_key = minio_secret_key
        self.client = Minio(self.minio_url, access_key=self.minio_access_key, secret_key=self.minio_secret_key, secure=False)
    
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
        file_path_w_name_no_cont = separator.join(
            blob_path.split(separator)[1:])
        
        container_name = separator.join(
            blob_path.split(separator)[0:1])
        
        # Generate a pre-signed URL for the blob
        try:
            url = self.client.presigned_get_object(container_name, file_path_w_name_no_cont, expires=timedelta(hours=1))
            logging.info("Path and pre-signed URL for file in MinIO storage are now generated \n")
            return url
        except S3Error as err:
            logging.error(f"Failed to generate pre-signed URL: {err}")
            return None
