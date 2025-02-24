# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

'''
Command line functional test runner
'''
import argparse
import base64
import os
import time
from datetime import datetime, timedelta  # Add this import
from rich.console import Console
import rich.traceback
from azure.storage.blob import BlobServiceClient
from azure.identity import  AzureCliCredential, DefaultAzureCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexerClient
from azure.core.exceptions import HttpResponseError
import socket
import requests
from typing import Tuple

def get_ip_addresses() -> Tuple[str, str]:
    """Get both internal and external IP addresses"""
    try:
        # Get internal IP
        hostname = socket.gethostname()
        internal_ip = socket.gethostbyname(hostname)
        
        # Get external IP
        external_ip = requests.get('https://api.ipify.org').text
        
        console.print(f"🖥️ Internal IP: {internal_ip}")
        console.print(f"🌐 External IP: {external_ip}")
        
        return internal_ip, external_ip
    except Exception as e:
        console.print(f"[red]Failed to get IP addresses: {str(e)}[/red]")
        return None, None

def wait_for_rbac_propagation(blob_service_client, max_wait_minutes=30):
    """Wait for RBAC roles to propagate"""
    console.print("Checking RBAC role propagation...")
    start_time = datetime.now()
    timeout = start_time + timedelta(minutes=max_wait_minutes)
    
    while datetime.now() < timeout:
        try:
            # Try to list containers to verify permissions
            containers = list(blob_service_client.list_containers(maxresults=1))
            console.print("✅ RBAC roles successfully propagated")
            return True
        except Exception as e:
            minutes_elapsed = (datetime.now() - start_time).total_seconds() / 60
            console.print(f"⏳ Waiting for RBAC propagation... ({minutes_elapsed:.1f} minutes elapsed)")
            console.print(f"Error: {str(e)}")  # Add error details for debugging
            time.sleep(60)  # Wait 1 minute before trying again
            
    raise TestFailedError(f"RBAC roles did not propagate after {max_wait_minutes} minutes")


def get_azure_credential():
    try:
        # Try Azure CLI credential
        credential = AzureCliCredential()
        print("✅ Using Azure CLI Credentials")
        return credential
    except Exception as e:
        print(f"⚠️ Azure CLI Credentials failed: {str(e)}")
        print("↪️ Falling back to DefaultAzureCredential")
        return DefaultAzureCredential()

# Use the credential
azure_credential = get_azure_credential()

rich.traceback.install()
console = Console()

class TestFailedError(Exception):
    """Exception raised when a test fails"""

# Define top-level variables
UPLOAD_CONTAINER_NAME = "upload"
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
        "--storage_account_url",
        required=True,
        help="Storage account endpoint string (set in extract-env)")
    parser.add_argument(
        "--search_service_endpoint",
        required=True,
        help="Azure Search Endpoint")
    parser.add_argument(
        "--search_index",
        required=True,
        help="Azure Search Index")
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

def main(blob_service_client, wait_time_seconds, test_file_names, search_service_endpoint, search_index):
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

        # Wait for the indexer to run
        time.sleep(60)
        get_indexer_status(search_service_endpoint, search_index)

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

def get_indexer_status(search_service_endpoint, search_index):
    """Function to get the status of the Azure Search indexer"""
    try:
        indexer_client = SearchIndexerClient(
            endpoint=search_service_endpoint,
            credential=azure_credential,
        )
        console.print("Getting indexer status...")

        indexer_status = indexer_client.get_indexer_status("indexer")
        console.print(f"Indexer status: {indexer_status.status}")
        console.print(f"Indexer last result: {indexer_status.last_result.status}")
        console.print(f"Indexer error message: {indexer_status.last_result.error_message}")

        if indexer_status.status != "running" or indexer_status.last_result.status != "success":
            raise TestFailedError(f"Indexer status is not running or last result is not success. Status: {indexer_status.status}, Last result: {indexer_status.last_result.status}")

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex
    
# Check Search Index for specific content uploaded by test
def check_index(search_service_endpoint, search_index):
    """Function to check the index for specific content uploaded by the test"""
    try:
        search_client = SearchClient(
            endpoint=search_service_endpoint,
            index_name=search_index,
            credential=azure_credential,
        )
        console.print("Beginning index search")
        for extension, query in search_queries.items():
            try: 
                search_results = search_client.search(query, top=20)

                if search_results:
                    search_results.get_count()
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
            except HttpResponseError as e:
                console.print(f"[red]Error while searching for query '{query}' with extension '{extension}': {e}[/red]")
                raise

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

def cleanup_after_test(blob_service_client, search_service_endpoint, search_index, test_file_names):
    """Function to cleanup after tests"""
    console.print("Cleaning up after tests...")

    upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)
    search_client = SearchClient(
        endpoint=search_service_endpoint,
        index_name=search_index,
        credential=azure_credential,
    )

    # Cleanup upload container
    for file_name in test_file_names:
        console.print(f"Deleting blob: {UPLOAD_FOLDER_NAME}/{file_name}")
        upload_container_client.delete_blob(f'{UPLOAD_FOLDER_NAME}/{file_name}')

    console.print("Finished cleaning up after tests.")

def encode_document_id(document_id):
    """ encode a path/file name to remove unsafe chars ai search document id """
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
                # Check IP addresses before proceeding
        internal_ip, external_ip = get_ip_addresses()
        console.print("Starting tests with IP configuration:")
        console.print(f"Internal IP: {internal_ip}")
        console.print(f"External IP: {external_ip}")

        # Add RBAC propagation check

        storage_blob_service_client = BlobServiceClient(
            args.storage_account_url, credential=azure_credential)
        
        wait_for_rbac_propagation(storage_blob_service_client)
        # Get a list of files with specified extensions in the test_data folder
        test_file_names = get_files_by_extension(FILE_PATH, args.file_extensions)

        main(storage_blob_service_client, args.wait_time_seconds, test_file_names, args.search_service_endpoint, args.search_index)
        check_index(args.search_service_endpoint, args.search_index)
    finally:
        console.print("🧹 Cleanup...")
        cleanup_after_test(storage_blob_service_client,
                           args.search_service_endpoint,
                           args.search_index,
                           test_file_names)