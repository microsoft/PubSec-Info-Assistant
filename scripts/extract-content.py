# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script reads the content from the old RG and writes it to the new RG
# as an alterate igration path

from pyfiglet import Figlet
import json
import subprocess
import os
from azure.cosmos import CosmosClient, PartitionKey, exceptions
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from azure.storage.blob import BlobServiceClient, ContainerClient


# Helper function for getting the appropriate Azure CLI Vault URL
def get_keyvault_url(keyvault_name, resource_group=None):
    """ Return vault url
    """    
    command = ["az", "keyvault", "show", "--name", keyvault_name]
    if resource_group:
        command.extend(["--resource-group", resource_group])
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print("Error executing command:", result.stderr)
        return None
    data = json.loads(result.stdout)
    vault_url = data.get("properties", {}).get("vaultUri")
    return vault_url


# Send multiple docs to index
def index_sections(chunks):
    """ Pushes a batch of content to the search index
    """    
    results = new_search_client.upload_documents(documents=chunks)
    succeeded = sum([1 for r in results if r.succeeded])
    print(f"\tIndexed {len(results)} chunks, {succeeded} succeeded")


def get_storage_account_endpoint(storage_account_name):
    # Prepare the Azure CLI command
    command = [
        "az", "storage", "account", "show",
        "--name", storage_account_name,
        "--query", "primaryEndpoints",
        "--output", "json"  
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode == 0:
        # Parse the JSON output
        endpoint = json.loads(result.stdout)
        return endpoint
    else:
        print("Failed to retrieve endpoints. Error:", result.stderr)
        return None


f = Figlet()
print(f.renderText('Extract and Migrate Content'))


# *************************************************************************
# Read required values from infra_output.json or config & key vault

# if 'infra_output.json' does not exist
cwd = os.getcwd()  # Get the current working directory
config_file_path = os.path.join(cwd, "scripts", "upgrade_repoint.config.json")

with open(config_file_path, 'r') as file:
    env = json.load(file)
    old_resource_group = env['old_env']['resource_group']
    old_random_text = env['old_env']['random_text'].lower()   
    new_resource_group = env['new_env']['resource_group']
    new_random_text = env['new_env']['random_text'].lower()   

credential = DefaultAzureCredential()

old_key_vault_name = f'infoasst-kv-{old_random_text}'
old_key_vault_url = get_keyvault_url(old_key_vault_name)
old_secret_client = SecretClient(vault_url=old_key_vault_url, credential=credential) 

new_key_vault_name = f'infoasst-kv-{new_random_text}'
new_key_vault_url = get_keyvault_url(new_key_vault_name)
new_secret_client = SecretClient(vault_url=new_key_vault_url, credential=credential) 

old_cosmosdb_url = f'https://infoasst-cosmos-{old_random_text}.documents.azure.com:443/'
old_cosmosdb_key = old_secret_client.get_secret('COSMOSDB-KEY').value
old_search_endpoint = f'https://infoasst-search-{old_random_text}.search.windows.net'
old_blob_connection_string = old_secret_client.get_secret('BLOB-CONNECTION-STRING').value
old_search_key = old_secret_client.get_secret('AZURE-SEARCH-SERVICE-KEY').value 
old_azure_blob_storage_account = f"infoasststore{old_random_text}"
old_azure_blob_storage_key = old_secret_client.get_secret('AZURE-BLOB-STORAGE-KEY').value 
old_azure_blob_storage_kendpoint = get_storage_account_endpoint(old_azure_blob_storage_account)


new_search_key = new_secret_client.get_secret('AZURE-SEARCH-SERVICE-KEY').value
new_search_endpoint = f'https://infoasst-search-{new_random_text}.search.windows.net'
new_cosmosdb_url = f'https://infoasst-cosmos-{new_random_text}.documents.azure.com:443/'
new_cosmosdb_key = new_secret_client.get_secret('COSMOSDB-KEY').value
new_blob_connection_string = new_secret_client.get_secret('BLOB-CONNECTION-STRING').value
new_azure_blob_storage_account = f"infoasststore{new_random_text}"
new_azure_blob_storage_key = new_secret_client.get_secret('AZURE-BLOB-STORAGE-KEY').value 
new_azure_blob_storage_kendpoint = get_storage_account_endpoint(new_azure_blob_storage_account)

index_name = 'vector-index'

old_search_client = SearchClient(endpoint=old_search_endpoint, index_name=index_name, credential=AzureKeyCredential(old_search_key))
new_search_client = SearchClient(endpoint=new_search_endpoint, index_name=index_name, credential=AzureKeyCredential(new_search_key))



# *************************************************************************
# Migrate Search
print(f.renderText('Search index'))
blob_service_client = BlobServiceClient.from_connection_string(old_blob_connection_string)
container_name = "content"
container_client = blob_service_client.get_container_client(container_name)

try:
    blob_list = container_client.list_blobs()
    index_chunks = []
    i = 0
    for blob in blob_list:
        # retrieve all chunk entries in the search index for this blob
        results = old_search_client.search(
            search_text="*",
            select="*",
            filter=f"chunk_file eq '{blob.name}'"
        )        

        for result in results:          
            # repoint the file uri
            old_file_uri = result['file_uri']
            new_file_uri = old_file_uri.replace(old_random_text, new_random_text)

            # Prepare the index schema based representation of the chunk with the embedding
            index_chunk = {}
            index_chunk['id'] = result['id']
            index_chunk['processed_datetime'] = result['processed_datetime']
            index_chunk['file_name'] = result['file_name']
            index_chunk['file_uri'] = new_file_uri
            index_chunk['folder'] = result['folder']
            index_chunk['tags'] = result['tags']
            index_chunk['chunk_file'] = result['chunk_file']
            index_chunk['file_class'] = result['file_class']
            index_chunk['title'] = result['title']
            index_chunk['pages'] = result['pages']
            index_chunk['translated_title'] = result['translated_title']
            index_chunk['content'] = result['content']
            index_chunk['contentVector'] = result['contentVector']
            index_chunk['entities'] = result['entities']
            index_chunk['key_phrases'] = result['key_phrases']
            index_chunks.append(index_chunk)

        # push batch of content to index, rather than each individual chunk
        i += 1
        if i % 200 == 0:
            index_sections(index_chunks)
            index_chunks = []
            i = 0

    # push remainder chunks content to index
    if len(index_chunks) > 0:
        index_sections(index_chunks)

except Exception as e:
    print(e)



# *************************************************************************
# Migrate cosmos db and merge db's
print(f.renderText('Cosmos DB'))
try:
    max_item_count = 1

    # Get old status docs
    old_cosmos_client = CosmosClient(old_cosmosdb_url, old_cosmosdb_key)
    old_status_database = old_cosmos_client.get_database_client('statusdb')
    old_status_container = old_status_database.get_container_client('statuscontainer')
    old_tags_database = old_cosmos_client.get_database_client('tagdb')
    old_tags_container = old_tags_database.get_container_client('tagcontainer')
    new_cosmos_client = CosmosClient(new_cosmosdb_url, new_cosmosdb_key)
    new_status_database = new_cosmos_client.get_database_client('statusdb')
    new_status_container = new_status_database.get_container_client('statuscontainer')



    # Get status items using paging incase the dataset is bigger than can be returned in one call
    status_json_docs = []
    query = 'SELECT * from c'
    query_iterable = old_status_container.query_items(
        query=query,
        enable_cross_partition_query=True,
        max_item_count=1
    )
    try:
        pager = query_iterable.by_page()
        while True:
            json_docs = list(pager.next()) 
            # Process your docs
            if json_docs:
                # Process your doc 
                for json_doc in json_docs:
                    status_json_docs.append(json_doc)                                
            else:
                break  # If no documents are returned, break the loop
    except StopIteration:
        # Handle the end of the pagination gracefully
        print("Retrieved status docs")

    # Get the tags items
    tags_json_docs = []
    query = 'SELECT * from c'
    query_iterable = old_tags_container.query_items(
        query=query,
        enable_cross_partition_query=True,
        max_item_count=1
    )
    try:
        pager = query_iterable.by_page()
        while True:
            json_docs = list(pager.next()) 
            # Process your docs
            if json_docs:
                # Process your doc 
                for json_doc in json_docs:
                    tags_json_docs.append(json_doc)                                
            else:
                break  # If no documents are returned, break the loop
    except StopIteration:
        # Handle the end of the pagination gracefully
        print("Retrieved tags docs")

    # Create a dictionary from old_tags_items for faster lookup
    tags_dict = {item['id']: item['tags'] for item in tags_json_docs}

    # Merge old tags and status json documents
    for item in status_json_docs:
        if item['id'] in tags_dict:
            item['tags'] = tags_dict[item['id']]

    # Write merged json documents to new RG statuscontainer
    for item in status_json_docs:
        new_status_container.upsert_item(item)

except exceptions.CosmosHttpResponseError as e:
    print(f'An error occurred: {e}')


# *************************************************************************
# Migrate upload storage account container blobs
print(f.renderText('Storage upload container'))
container_name = "upload"
old_blob_service_client = BlobServiceClient.from_connection_string(old_blob_connection_string)
old_container_client = old_blob_service_client.get_container_client(container_name)
new_blob_service_client = BlobServiceClient.from_connection_string(new_blob_connection_string)
new_container_client = new_blob_service_client.get_container_client(container_name)

try:
    blob_list = old_container_client.list_blobs()
    index_chunks = []
    i = 0
    for blob in blob_list:
        # write each blob to the new storage account
        old_blob_client = old_container_client.get_blob_client(blob)
        blob_data = old_blob_client.download_blob().readall()

        new_blob_client = new_container_client.get_blob_client(blob.name)
        metadata = {"do-not-process": "true"}
        new_blob_client.upload_blob(blob_data, overwrite=True, metadata=metadata)                     

except Exception as e:
    print(e)


# *************************************************************************
# Migrate content storage account container blobs
print(f.renderText('Storage content container'))
container_name = "content"
old_container_client = old_blob_service_client.get_container_client(container_name)
new_container_client = new_blob_service_client.get_container_client(container_name)

try:
    blob_list = old_container_client.list_blobs()
    index_chunks = []
    i = 0
    for blob in blob_list:
        # write each blob to the new storage account
        old_blob_client = old_container_client.get_blob_client(blob)
        blob_data = old_blob_client.download_blob().readall()
        data = json.loads(blob_data)

        # repoint the file_uri key-value to the blob in the new upload container
        old_uri = data['file_uri']
        new_uri = old_uri.replace(old_random_text, new_random_text)
        data['file_uri'] = new_uri 
        modified_blob_data = json.dumps(data)

        new_blob_client = new_container_client.get_blob_client(blob.name)
        new_blob_client.upload_blob(modified_blob_data, overwrite=True)                     

except Exception as e:
    print(e)

print('done')