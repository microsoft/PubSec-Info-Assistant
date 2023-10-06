'''
Command line functional test runner
'''
import argparse
from rich.console import Console
import rich.traceback
import os
import sys
import time
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
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
WAIT_TIME_SECONDS = 600  # 10 minutes
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

    return parser.parse_args()

def main(storage_account_connection_str):
    try:
        # Create a BlobServiceClient
        blob_service_client = BlobServiceClient.from_connection_string(storage_account_connection_str)

        # Upload the files to the container
        upload_container_client = blob_service_client.get_container_client(UPLOAD_CONTAINER_NAME)

        with open(os.path.join(FILE_PATH, DOCX_FILE_NAME), "rb") as docx_file:
            upload_container_client.upload_blob(DOCX_FILE_NAME, docx_file.read())

        with open(os.path.join(FILE_PATH, PDF_FILE_NAME), "rb") as pdf_file:
            upload_container_client.upload_blob(PDF_FILE_NAME, pdf_file.read())

        with open(os.path.join(FILE_PATH, HTML_FILE_NAME), "rb") as html_file:
            upload_container_client.upload_blob(HTML_FILE_NAME, html_file.read())    

        console.print("Test Files uploaded successfully.")

        # Wait 10 minutes for pipeline processing
        console.print(f"Waiting for {WAIT_TIME_SECONDS // 60} minutes for pipeline processing...")
        time.sleep(WAIT_TIME_SECONDS)

        # Check for output files in the "output" container
        output_container_client = blob_service_client.get_container_client(OUTPUT_CONTAINER_NAME)

        for directory_name in [DOCX_FILE_NAME, PDF_FILE_NAME, HTML_FILE_NAME]:
        # Construct the prefix to represent the directory path and check if empty
            prefix = f"{directory_name}/"
            blobs = list(output_container_client.list_blobs(name_starts_with=prefix))

            if blobs:
                console.print(f"Directory '{directory_name}' in the 'content' container is not empty.")
                # Remove after confirming files exist
                for blob in blobs:
                    output_container_client.delete_blob(blob.name)
            else:
                console.print(f"Directory '{directory_name}' in the 'content' container is empty.")
                raise TestFailedError(f"Directory '{directory_name}' is empty in the 'content' container.")

    except (Exception, TestFailedError) as ex:
        exit_status = 1
        console.log(f'[red]❌ {ex}[/red]')
        sys.exit(exit_status)

    finally:
        # Cleanup upload container
        upload_container_client.delete_blob(DOCX_FILE_NAME)
        upload_container_client.delete_blob(PDF_FILE_NAME)

# Check Search Index for specific content uploaded by test
def check_index(search_service_endpoint, search_index, search_key ):
    exit_status = 0
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
        sys.exit(exit_status)

    finally:
        sys.exit(exit_status)

if __name__ == '__main__':
    args = parse_arguments()
    main(args.storage_account_connection_str)
    check_index(args.search_service_endpoint, args.search_index, args.search_key)
