# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script manages the migration of your content from version 1.0 to 1.1
#
# To use this script, you need to:
# 1. Have run make deploy to create a new IA resource group
# 2. Copy over the inf_output.json file from the output folder of the 1.0 deployment
#    to the scripts folder of the 1.1 deployment and rename if to in_output_old.json
# 3. run make run-migration to perfomr the migration
#
# The script will:
# 1. Read required values from in_output.json
# 2. Read required values from in_output_old.json
# 3. Read required secrets from azure keyvault
# 4. Migrate Cosmos DB tags from the old tags container and database to the


from pyfiglet import Figlet
import json
import os
from azure.cosmos import CosmosClient, PartitionKey, exceptions
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

f = Figlet()
print(f.renderText('Migration from 1.0 to 1.1'))
print("Current Working Directory:", os.getcwd())
# Read required secrets from azure keyvault
credential = DefaultAzureCredential()


# *************************************************************************
# Read required NEW values from in_output.json & new key vault
print("Reading values from inf_output.json")
with open('inf_output.json', 'r') as file:
    inf_output = json.load(file)
    
cosmosdb_url_new = inf_output['AZURE_COSMOSDB_URL']['value']
key_vault_name_new = inf_output['DEPLOYMENT_KEYVAULT_NAME']['value']
key_vault_url_new = "https://" + key_vault_name_new + ".vault.azure.net/"

client_new = SecretClient(vault_url=key_vault_url_new, credential=credential) 
cosmosdb_key_new = client_new.get_secret('COSMOSDB-KEY') 
# *************************************************************************


# *************************************************************************
# Read required OLD values from in_output_old.json & old key vault
print("Reading values from infra_output.json")
with open('infra_output.json', 'r') as file:
    inf_output = json.load(file)
    
cosmosdb_url_old = inf_output['properties']['outputs']['azurE_COSMOSDB_URL']['value']
key_vault_name_old = inf_output['properties']['outputs']['deploymenT_KEYVAULT_NAME']['value']
key_vault_url_old = "https://" + key_vault_name_old + ".vault.azure.net/"

# Read required secrets from azure keyvault
client_old = SecretClient(vault_url=key_vault_url_old, credential=credential) 
cosmosdb_key_old = client_old.get_secret('COSMOSDB-KEY')
# *************************************************************************


# *************************************************************************
# Migrate Cosmos DB tags from the old tags container and database to the
# status container and database as these have now been merged
client = CosmosClient(cosmosdb_url_old, cosmosdb_key_old.value)

try:
    # Get old status docs
    database = client.get_database_client('statusdb')
    container = database.get_container_client('statuscontainer')
    old_status_items = list(container.query_items(
        query="SELECT * FROM c",
        enable_cross_partition_query=True
    ))
    
    # Get old tags docs
    database = client.get_database_client('tagdb')
    container = database.get_container_client('tagcontainer')
    old_tags_items = list(container.query_items(
        query="SELECT * FROM c",
        enable_cross_partition_query=True
    ))
    
    # Create a dictionary from old_tags_items for faster lookup
    tags_dict = {item['id']: item['tags'] for item in old_tags_items}
    
    # Merge old tags and status json documents
    for item in old_status_items:
        if item['id'] in tags_dict:
            item['tags'] = tags_dict[item['id']]
            item['migration_log'] = [f'Migrated tags & status from {cosmosdb_url_old} old tags container to status container']
        
    # Write merged json documents to the new cosmos database
    client = CosmosClient(cosmosdb_url_new, credential=cosmosdb_key_new.value)
    database_new = client.get_database_client('statusdb')
    container_new = database_new.get_container_client('statuscontainer')                  #   <---  change this before PR *********************************
    for item in old_status_items:
        container_new.upsert_item(item)
    
except exceptions.CosmosHttpResponseError as e:
    print(f'An error occurred: {e}')
    
# *************************************************************************