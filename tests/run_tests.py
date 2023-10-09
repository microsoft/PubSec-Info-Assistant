# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

'''
Command line functional test runner
'''
import argparse
import base64
from rich.console import Console
import rich.traceback
import os
import sys
import time
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential

rich.traceback.install()
console = Console()

class TestFailedError(Exception):
    pass

# Define top-level variables
UPLOAD_CONTAINER_NAME = "upload"
OUTPUT_CONTAINER_NAME = "content"
FILE_PATH = "./"  # Folder containing the files to upload
DOCX_FILE_NAME = "example.docx"
PDF_FILE_NAME = "example.pdf"
HTML_FILE_NAME = "example.html"
UPLOAD_FOLDER_NAME = "functional-test"
MAX_DURATION = 1200  # 20 minutes
search_queries = [
    "Each brushstroke and note played adds to the vibrant tapestry of human culture,",                         # From example.pdf
    "Sed non urna nec elit auctor elementum. Sed auctor eget urna at faucibus.",                               # From example.docx
    "Regeringen investerer i infrastrukturudvikling for at opretholde moderne og effektive transportsystemer"  # From example.html
]

def parse_arguments():
    """
    Parse command line arguments
    Note that extract_env must be ran before this script is invoked
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--storage_account_connection_str",
        required=True,
        help="Storage account connection string (set in extract-env)")
    parser.add_argument(
        "--search_service_endpoint",
        required=True,
        help="Azure Search Endpoint")
    parser.add_argument(
        "--search_index",
        required=True,
        help="Azure Search Index")
    parser.add_argument(
        "--search_key",
        required=True,
        help="Azure Search Key")
    parser.add_argument(
        "--wait_time_seconds",
        required=False,
        default=300,
        help="Wait time in seconds for pipeline processing (default 300)")

    return parser.parse_args()

def main(blob_service_client, wait_time_seconds):
    try:
        current_duration = 0
        # Upload the files to the container
        upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)

        with open(os.path.join(FILE_PATH, DOCX_FILE_NAME), "rb") as docx_file:
            upload_container_client.upload_blob(f'{UPLOAD_FOLDER_NAME}/{DOCX_FILE_NAME}', docx_file.read())

        with open(os.path.join(FILE_PATH, PDF_FILE_NAME), "rb") as pdf_file:
            upload_container_client.upload_blob(f'{UPLOAD_FOLDER_NAME}/{PDF_FILE_NAME}', pdf_file.read())

        with open(os.path.join(FILE_PATH, HTML_FILE_NAME), "rb") as html_file:
            upload_container_client.upload_blob(f'{UPLOAD_FOLDER_NAME}/{HTML_FILE_NAME}', html_file.read())    

        console.print("Test Files uploaded successfully.")

        # Check for output files in the "output" container
        output_container_client = blob_service_client.get_container_client(OUTPUT_CONTAINER_NAME)
        
        test_files = [DOCX_FILE_NAME, PDF_FILE_NAME, HTML_FILE_NAME]
        # Dictionary to track the status of each file
        status = {file: False for file in test_files}
        
        while current_duration < MAX_DURATION:
            # Wait 10 minutes for pipeline processing
            console.print(f"Waiting for {int(wait_time_seconds) // 60} minutes for pipeline processing...")
            time.sleep(int(wait_time_seconds))

            for test_file in test_files:
                if not status[test_file]:
                    # Construct the prefix to represent the directory path and check if empty
                    file_path = f"{UPLOAD_FOLDER_NAME}/{test_file}/"
                    blobs = list(output_container_client.list_blobs(name_starts_with=file_path))

                    if blobs:
                        console.print(f"Directory '{file_path}' in the 'content' container is populated.")
                        status[test_file] = True
                    else:
                        if current_duration + int(wait_time_seconds) >= MAX_DURATION:
                            raise TestFailedError(f"Directory '{file_path}' is empty in the 'content' container.")
                        else:
                            console.print(f"Directory '{file_path}' in the 'content' container is empty. Checking again... ")
                    
            if all(status.values()):
                console.print("All test files have been successfully processed.")
                break

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

# Check Search Index for specific content uploaded by test
def check_index(search_service_endpoint, search_index, search_key ):
    """Function to check the index for specific content uploaded by the test"""
    try:
        azure_search_key_credential = AzureKeyCredential(search_key)
        search_client = SearchClient(
            endpoint=search_service_endpoint,
            index_name=search_index,
            credential=azure_search_key_credential,
        )

        for query in search_queries:
            search_results = search_client.search(query)

            if search_results:
                console.print(f"Specified content for query '{query}' exists in the index.")
                ### For Debugging results
                # for result in search_results:
                #     console.print("Result:")
                #     for key, value in result.items():
                #         console.print(f"{key}: {value}")
                #         console.print()
            else:
                console.print(f"Content for query '{query}' does not exist in the index.")
                raise TestFailedError(f"Content for query '{query}' does not exist in the index.")
        
    except (Exception, TestFailedError) as ex:
        exit_status = 1
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

def cleanup_after_test(blob_service_client, search_service_endpoint, search_index, search_key):
    console.print(f"Cleaning up after tests...")

    upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)
    output_container_client = blob_service_client.get_container_client(OUTPUT_CONTAINER_NAME)
    azure_search_key_credential = AzureKeyCredential(search_key)
    search_client = SearchClient(
        endpoint=search_service_endpoint,
        index_name=search_index,
        credential=azure_search_key_credential,
    )

    # Cleanup upload container
    upload_container_client.delete_blob(f'{UPLOAD_FOLDER_NAME}/{DOCX_FILE_NAME}')
    upload_container_client.delete_blob(f'{UPLOAD_FOLDER_NAME}/{PDF_FILE_NAME}')
    upload_container_client.delete_blob(f'{UPLOAD_FOLDER_NAME}/{HTML_FILE_NAME}')
    
    # Cleanup output container
    blobs = output_container_client.list_blobs(name_starts_with=UPLOAD_FOLDER_NAME)
    for blob in blobs:
        print(f"Deleting blob: {blob.name}")
        output_container_client.delete_blob(blob.name)
        # Cleanup search index
        print(f"Removing document from index: {blob.name} : id : {encode_document_id(blob.name)}")
        search_client.delete_documents(documents=[{"id": f"{encode_document_id(blob.name)}"}])

    console.print(f"Finished cleaning up after tests.")

def encode_document_id(document_id):
    """ encode a path/file name to remove unsafe chars for a cosmos db id """
    safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
    return safe_id

if __name__ == '__main__':
    args = parse_arguments()
    try:
        storage_blob_service_client = BlobServiceClient.from_connection_string(args.storage_account_connection_str)
        main(storage_blob_service_client, args.wait_time_seconds)
        check_index(args.search_service_endpoint, args.search_index, args.search_key)
    finally:
        cleanup_after_test(storage_blob_service_client, args.search_service_endpoint, args.search_index, args.search_key)
