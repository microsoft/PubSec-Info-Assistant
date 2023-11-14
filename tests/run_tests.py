# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

'''
Command line functional test runner
'''
import argparse
import base64
import os
import time
from datetime import datetime, timedelta, timezone
from rich.console import Console
import rich.traceback
from azure.storage.blob import BlobServiceClient
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential

rich.traceback.install()
console = Console()

class TestFailedError(Exception):
    """Exception raised when a test fails"""

# Define top-level variables
UPLOAD_CONTAINER_NAME = "upload"
OUTPUT_CONTAINER_NAME = "content"
FILE_PATH = "./test_data"  # Folder containing the files to upload
UPLOAD_FOLDER_NAME = "functional-test"
MAX_DURATION = 2700  # 45 minutes

search_queries = {
    "pdf": "Each brushstroke and note played adds to the vibrant tapestry of human culture,",  
    "docx": "Sed non urna nec elit auctor elementum. Sed auctor eget urna at faucibus.",  
    "html": "Regeringen investerer i infrastrukturudvikling for at opretholde moderne og effektive transportsystemer", 
    "jpg": "This word, nothing. blank not space.",  
    "png": "kitten animal kitty funny OCR Text: FAILED DOO WIITH DAILY DRIGDETY",  
    "csv": "<td>Hill, Freeman and Johnson</td> <td>xcarter@example.com</td> <td>61</td> </tr> <tr> <td>Johnson Group</td>", 
    "md": "Viel Spaß beim Entdecken und Üben dieser Wörter!",  
    "pptx": "Randomly Generated For PPTX This data test Title for PPTX Text paragraph in power point",  
    "txt": "The deep green that isn't the color of clouds, but came with these.",  
    "xlsx": "<td>Turnerhaven</td> <td>9580 Boyd Point Suite 139</td> <td>67199</td>", 
    "xml": "John Doe john.doe@example.com 123-456-7890 42 Alice Smith"  
}

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
    parser.add_argument(
        "--file_extensions",
        required=True,
        nargs="+", 
        help="List of file types for test")

    return parser.parse_args()

def main(blob_service_client, wait_time_seconds, test_file_names):
    """Main function to run functional tests"""
    try:
        current_duration = 0

        #Wait for deployment to settle
        time.sleep(15)
        
        # Upload the files to the container
        upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)

        # Get a list of files with specified extensions in the test_data folder
        test_files = get_files_by_extension(FILE_PATH, test_file_names)

        for test_file in test_files:
            with open(os.path.join(FILE_PATH, test_file), "rb") as file:
                # Upload the file to the container
                file_name = os.path.basename(test_file)
                console.print(f"Uploading '{file_name}'")
                upload_container_client.upload_blob(f'{UPLOAD_FOLDER_NAME}/{file_name}', file.read())
                time.sleep(5)

        console.print("Test Files uploaded successfully.")

        # Check for output files in the "output" container
        output_container_client = blob_service_client.get_container_client(OUTPUT_CONTAINER_NAME)

        # Dictionary to track the status of each file
        status = {file: False for file in test_files}

        while current_duration < MAX_DURATION:
            # Wait 10 minutes for pipeline processing
            console.print(f"Waiting for {int(wait_time_seconds) // 60} \
                          minutes for pipeline processing...")
            time.sleep(int(wait_time_seconds))
            current_duration += int(wait_time_seconds)

            for test_file in test_files:
                if not status[test_file]:
                    # Construct the prefix to represent the directory path and check if empty
                    file_path = f"{UPLOAD_FOLDER_NAME}/{test_file}/"
                    blobs = list(output_container_client.list_blobs(name_starts_with=file_path))

                    if blobs:
                        console.print(f"Directory '{file_path}' in the 'content' \
                                      container is populated.")
                        status[test_file] = True
                    else:
                        if current_duration + int(wait_time_seconds) >= MAX_DURATION:
                            raise TestFailedError(f"Directory '{file_path}' is empty in \
                                                  the 'content' container.")
                        else:
                            console.print(f"Directory '{file_path}' in the 'content' \
                                          container is empty. Checking again... ")

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
        console.print("Begining index search")
        for extension, query in search_queries.items():
            search_results = search_client.search(query, top=20)

            if search_results:
                # Iterate through search results
                for result in search_results:
                    file_name = result.get("file_name")

                    if file_name and f'test_example.{extension}' in file_name.lower():
                        console.print(f"Specified content for query '{query}' with extension '{extension}' exists in the index.")
                        console.print(f"Result: {file_name}")
                        break
            else:
                console.print(f"Content for query with extension '{extension}' does not exist in the index.")
                raise TestFailedError(f"Content for query with extension '{extension}' does not exist in the index.")

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

def cleanup_after_test(blob_service_client, search_service_endpoint, search_index, search_key, test_file_names):
    """Function to cleanup after tests"""
    console.print("Cleaning up after tests...")

    upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)
    output_container_client = blob_service_client.get_container_client(OUTPUT_CONTAINER_NAME)
    azure_search_key_credential = AzureKeyCredential(search_key)
    search_client = SearchClient(
        endpoint=search_service_endpoint,
        index_name=search_index,
        credential=azure_search_key_credential,
    )

    # Cleanup upload container
    for file_name in test_file_names:
        console.print(f"Deleting blob: {UPLOAD_FOLDER_NAME}/{file_name}")
        upload_container_client.delete_blob(f'{UPLOAD_FOLDER_NAME}/{file_name}')

    # Cleanup output container
    blobs = output_container_client.list_blobs(name_starts_with=UPLOAD_FOLDER_NAME)
    for blob in blobs:
        try:
            output_container_client.delete_blob(blob.name)
            console.print(f"Deleted blob: {blob.name}")
        except Exception as ex:
            console.print(f"Failed to delete blob: {blob.name}. Error: {ex}")

        try:
            # Cleanup search index
            console.print(f"Removing document from index: {blob.name} \
                          : id : {encode_document_id(blob.name)}")
            search_client.delete_documents(documents=[{"id": f"{encode_document_id(blob.name)}"}])
        except Exception as ex:
            console.print(f"Failed to remove document from index: {blob.name} \
                          : id : {encode_document_id(blob.name)}. Error: {ex}")

    console.print("Finished cleaning up after tests.")

def encode_document_id(document_id):
    """ encode a path/file name to remove unsafe chars for a cosmos db id """
    safe_id = base64.urlsafe_b64encode(document_id.encode()).decode()
    return safe_id

def get_files_by_extension(folder_path, extensions):
    """Get a list of files in the folder_path with specified extensions."""
    matching_files = []
    for root, _, files in os.walk(folder_path):
        for file_name in files:
            if any(file_name.endswith(extension) for extension in extensions):
                matching_files.append(file_name)  # Use os.path.basename to get just the file name
    return matching_files

if __name__ == '__main__':
    args = parse_arguments()
    try:
        storage_blob_service_client = BlobServiceClient.from_connection_string(
            args.storage_account_connection_str)
        # Get a list of files with specified extensions in the test_data folder
        test_file_names = get_files_by_extension(FILE_PATH, args.file_extensions)

        main(storage_blob_service_client, args.wait_time_seconds, test_file_names)
        check_index(args.search_service_endpoint, args.search_index, args.search_key)
    finally:
        cleanup_after_test(storage_blob_service_client,
                           args.search_service_endpoint,
                           args.search_index,
                           args.search_key,
                           test_file_names)
