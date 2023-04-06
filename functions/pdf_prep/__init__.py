import logging
import azure.functions as func
import os
import sys
from PyPDF2 import PdfReader, PdfWriter
from datetime import datetime, timedelta
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
import urllib.request
import glob
import io
import argparse


def main(myblob: func.InputStream):
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")

    # If a pdf then split file
    if is_pdf(myblob.name):
        logging.info("processing pdf")

        azure_blob_storage_account = os.environ["AZURE_BLOB_STORAGE_ACCOUNT"]
        azure_blob_drop_storage_container = os.environ["AZURE_BLOB_DROP_STORAGE_CONTAINER"]
        azure_blob_content_storage_container = os.environ["AZURE_BLOB_CONTENT_STORAGE_CONTAINER"]
        azure_blob_storage_key = os.environ["AZURE_BLOB_STORAGE_KEY"]
        base_filename = os.path.basename(myblob.name)

        # Get path and file name minus the root container
        separator = "/"
        File_path_and_name_no_container = separator.join(
            myblob.name.split(separator)[1:])

        # Get the folders to use when creating the new PDFs
        folder_set = File_path_and_name_no_container.removesuffix(
            f'/{base_filename}')

        # Gen SAS token
        sas_token = generate_blob_sas(
            account_name=azure_blob_storage_account,
            container_name=azure_blob_drop_storage_container,
            blob_name=File_path_and_name_no_container,
            account_key=azure_blob_storage_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.utcnow() + timedelta(hours=1)
        )
        source_blob_path = f'https://{azure_blob_storage_account}.blob.core.windows.net/{myblob.name}?{sas_token}'
        source_blob_path = source_blob_path.replace(" ", "%20")

        response = urllib.request.urlopen(source_blob_path)
        pdf_bytes = response.read()      # a bytes object
        pdf_file = io.BytesIO(pdf_bytes)
        pdf_reader = PdfReader(pdf_file)
        pages = pdf_reader.pages

        blob_service_client = BlobServiceClient(
            f'https://{azure_blob_storage_account}.blob.core.windows.net/', azure_blob_storage_key)
        for i in range(len(pages)):
            output_filename = os.path.splitext(os.path.basename(base_filename))[
                0] + f"-{i}" + ".pdf"
            writer = PdfWriter()
            writer.add_page(pages[i])

            with io.BytesIO() as bytes_stream:
                writer.write(bytes_stream)
                block_blob_client = blob_service_client.get_blob_client(
                    container=azure_blob_content_storage_container, blob=f'{folder_set}/{output_filename}')
                block_blob_client.upload_blob(
                    bytes_stream.getbuffer(), blob_type="BlockBlob", overwrite=True)
                bytes_stream.close()

    logging.info("Done")


def is_pdf(file_name):
    # Get the file extension using os.path.splitext
    file_ext = os.path.splitext(file_name)[1]
    # Return True if the extension is .pdf, False otherwise
    return file_ext == ".pdf"
