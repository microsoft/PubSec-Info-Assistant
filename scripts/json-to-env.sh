# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

echo "# Generated environment variables from bicep output"

jq -r  '
    .properties.outputs |
    [
        {
            "path": "azurE_LOCATION",
            "env_var": "LOCATION"
        },
        {
            "path": "azurE_SEARCH_INDEX",
            "env_var": "AZURE_SEARCH_INDEX"
        },
        {
            "path": "azurE_SEARCH_SERVICE",
            "env_var": "AZURE_SEARCH_SERVICE"
        },
        {
            "path": "azurE_SEARCH_SERVICE_ENDPOINT",
            "env_var": "AZURE_SEARCH_SERVICE_ENDPOINT"
        },
        {
            "path": "azurE_STORAGE_ACCOUNT",
            "env_var": "AZURE_BLOB_STORAGE_ACCOUNT"
        },
        {
            "path": "azurE_STORAGE_CONTAINER",
            "env_var": "AZURE_BLOB_STORAGE_CONTAINER"
        },
        {
            "path": "azurE_OPENAI_SERVICE",
            "env_var": "AZURE_OPENAI_SERVICE"
        },
        {
            "path": "backenD_URI",
            "env_var": "AZURE_WEBAPP_URI"
        },
        {
            "path": "backenD_NAME",
            "env_var": "AZURE_WEBAPP_NAME"
        },
        {
            "path": "resourcE_GROUP_NAME",
            "env_var": "RESOURCE_GROUP_NAME"
        },
        {
            "path": "coG_SERVICES_FOR_SEARCH_KEY",
            "env_var": "COGNITIVE_SERVICES_KEY"
        },
        {
            "path": "azurE_OPENAI_CHAT_GPT_DEPLOYMENT",
            "env_var": "AZURE_OPENAI_CHATGPT_DEPLOYMENT"
        },
        {
            "path": "azurE_OPENAI_EMBEDDING_MODEL",
            "env_var": "AZURE_OPENAI_EMBEDDING_MODEL"
        },       
        {
            "path": "azurE_OPENAI_SERVICE_KEY",
            "env_var": "AZURE_OPENAI_SERVICE_KEY"
        },
        {
            "path": "azurE_STORAGE_KEY",
            "env_var": "AZURE_BLOB_STORAGE_KEY"
        },
        {
            "path": "azurE_SEARCH_KEY",
            "env_var": "AZURE_SEARCH_SERVICE_KEY"
        },
        {
            "path": "azurE_FUNCTION_APP_NAME",
            "env_var": "AZURE_FUNCTION_APP_NAME"
        },
        {
            "path": "containeR_REGISTRY_NAME",
            "env_var": "CONTAINER_REGISTRY_NAME"
        },
        {
            "path": "containeR_APP_SERVICE",
            "env_var": "CONTAINER_APP_SERVICE"

        },
        {
            "path": "embeddingsqueue",
            "env_var": "EMBEDDINGS_QUEUE"
        },
        {
            "path": "azurE_STORAGE_CONTAINER",
            "env_var": "AZURE_STORAGE_CONTAINER"
        },
        {
            "path": "bloB_CONNECTION_STRING",
            "env_var": "BLOB_CONNECTION_STRING"
        },       
        {
            "path": "targeT_EMBEDDINGS_MODEL",
            "env_var": "TARGET_EMBEDDINGS_MODEL"
        },
        {
            "path": "azurE_COSMOSDB_URL",
            "env_var": "COSMOSDB_URL"
        },
        {
            "path": "azurE_COSMOSDB_KEY",
            "env_var": "COSMOSDB_KEY"
        },
        {
            "path": "azurE_COSMOSDB_DATABASE_NAME",
            "env_var": "COSMOSDB_DATABASE_NAME"
        },
        {
            "path": "azurE_COSMOSDB_CONTAINER_NAME",
            "env_var": "COSMOSDB_CONTAINER_NAME"
        },
        {
            "path": "azurE_OPENAI_RESOURCE_GROUP",
            "env_var": "AZURE_OPENAI_RESOURCE_GROUP"
        },
        {
            "path": "embeddinG_VECTOR_SIZE",
            "env_var": "EMBEDDING_VECTOR_SIZE"
        },       
        {
            "path": "iS_USGOV_DEPLOYMENT",
            "env_var": "IS_USGOV_DEPLOYMENT"
        },
        {
            "path": "bloB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "BLOB_STORAGE_ACCOUNT_ENDPOINT"
        }
    ]
        as $env_vars_to_extract
    |
    with_entries(
        select (
            .key as $a
            |
            any( $env_vars_to_extract[]; .path == $a)
        )
        |
        .key |= . as $old_key | ($env_vars_to_extract[] | select (.path == $old_key) | .env_var)
    )
    |
    to_entries
    | 
    map("export \(.key)=\"\(.value.value)\"")
    |
    .[]
    ' | sed "s/\"/'/g" # replace double quote with single quote to handle special chars
    