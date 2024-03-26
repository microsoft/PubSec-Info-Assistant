# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script manages the migration of your content from version 1.0 to 1.1
#
# To use this script, you need to:
# 1. Have run make deploy to create a new IA resource group
# 2. Ensure you have your infra_output.json file in root of your project (where package.json is)
#     This is where we will get information about your current bicep deployment
# 3. run make run-migration to perform the migration
#
# The script will:
# 1. Read required values from infra_output.json
# 2. Read required secrets from azure keyvault
# 3. Migrate Cosmos DB tags from the old tags container and database to the


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
# Read required values from infra_output.json & key vault
print("Reading values from infra_output.json")
with open('infra_output.json', 'r') as file:
    inf_output = json.load(file)
    
cosmosdb_url = inf_output['properties']['outputs']['azurE_COSMOSDB_URL']['value']
key_vault_name = inf_output['properties']['outputs']['deploymenT_KEYVAULT_NAME']['value']
key_vault_url = "https://" + key_vault_name + ".vault.azure.net/"

sClient = SecretClient(vault_url=key_vault_url, credential=credential) 
cosmosdb_key = sClient.get_secret('COSMOSDB-KEY') 
# *************************************************************************


# *************************************************************************
# Migrate Cosmos DB tags from the old tags container and database to the
# status container and database as these have now been merged
client = CosmosClient(cosmosdb_url, cosmosdb_key.value)

try:
    # Get old status docs
    status_database = client.get_database_client('statusdb')
    status_container = status_database.get_container_client('statuscontainer')
    old_status_items = list(status_container.query_items(
        query="SELECT * FROM c",
        enable_cross_partition_query=True
    ))
    
    # Get old tags docs
    tags_database = client.get_database_client('tagdb')
    tags_container = tags_database.get_container_client('tagcontainer')
    old_tags_items = list(tags_container.query_items(
        query="SELECT * FROM c",
        enable_cross_partition_query=True
    ))
    
    # Create a dictionary from old_tags_items for faster lookup
    tags_dict = {item['id']: item['tags'] for item in old_tags_items}
    
    # Merge old tags and status json documents
    for item in old_status_items:
        if item['id'] in tags_dict:
            item['tags'] = tags_dict[item['id']]
            item['migration_log'] = [f'Migrated tags & status from {cosmosdb_url} old tags container to status container']
        
    # Write merged json documents to statuscontainer
    for item in old_status_items:
        status_container.upsert_item(item)
    
    print(f'Successfully migrated {len(old_status_items)} items')
except exceptions.CosmosHttpResponseError as e:
    print(f'An error occurred: {e}')
    
# *************************************************************************