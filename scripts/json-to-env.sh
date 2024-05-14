# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

source ./scripts/load-env.sh > /dev/null 2>&1

echo "# Generated environment variables from terraform output"

jq -r  '
    [
        {
            "path": "AZURE_LOCATION",
            "env_var": "LOCATION"
        },
        {
            "path": "AZURE_SEARCH_INDEX",
            "env_var": "AZURE_SEARCH_INDEX"
        },
        {
            "path": "AZURE_SEARCH_SERVICE",
            "env_var": "AZURE_SEARCH_SERVICE"
        },
        {
            "path": "AZURE_SEARCH_SERVICE_ENDPOINT",
            "env_var": "AZURE_SEARCH_SERVICE_ENDPOINT"
        },
        {
            "path": "AZURE_STORAGE_ACCOUNT",
            "env_var": "AZURE_BLOB_STORAGE_ACCOUNT"
        },
        {
            "path": "AZURE_STORAGE_CONTAINER",
            "env_var": "AZURE_BLOB_STORAGE_CONTAINER"
        },
        {
            "path": "AZURE_OPENAI_SERVICE",
            "env_var": "AZURE_OPENAI_SERVICE"
        },
        {
            "path": "BACKEND_URI",
            "env_var": "AZURE_WEBAPP_URI"
        },
        {
            "path": "BACKEND_NAME",
            "env_var": "AZURE_WEBAPP_NAME"
        },
        {
            "path": "RESOURCE_GROUP_NAME",
            "env_var": "RESOURCE_GROUP_NAME"
        },
        {
            "path": "AZURE_OPENAI_CHAT_GPT_DEPLOYMENT",
            "env_var": "AZURE_OPENAI_CHATGPT_DEPLOYMENT"
        },
        {
            "path": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME",
            "env_var": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"
        },       
        {
            "path": "AZURE_FUNCTION_APP_NAME",
            "env_var": "AZURE_FUNCTION_APP_NAME"
        },
        {
            "path": "CONTAINER_REGISTRY_NAME",
            "env_var": "CONTAINER_REGISTRY_NAME"
        },
        {
            "path": "CONTAINER_APP_SERVICE",
            "env_var": "CONTAINER_APP_SERVICE"

        },
        {
            "path": "embeddingsqueue",
            "env_var": "EMBEDDINGS_QUEUE"
        },
        {
            "path": "AZURE_STORAGE_CONTAINER",
            "env_var": "AZURE_STORAGE_CONTAINER"
        },      
        {
            "path": "TARGET_EMBEDDINGS_MODEL",
            "env_var": "TARGET_EMBEDDINGS_MODEL"
        },
        {
            "path": "AZURE_COSMOSDB_URL",
            "env_var": "COSMOSDB_URL"
        },
        {
            "path": "AZURE_COSMOSDB_LOG_DATABASE_NAME",
            "env_var": "COSMOSDB_LOG_DATABASE_NAME"
        },
        {
            "path": "AZURE_COSMOSDB_LOG_CONTAINER_NAME",
            "env_var": "COSMOSDB_LOG_CONTAINER_NAME"
        },
        {
            "path": "AZURE_OPENAI_RESOURCE_GROUP",
            "env_var": "AZURE_OPENAI_RESOURCE_GROUP"
        },
        {
            "path": "EMBEDDING_VECTOR_SIZE",
            "env_var": "EMBEDDING_VECTOR_SIZE"
        },
        {
            "path": "BLOB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "BLOB_STORAGE_ACCOUNT_ENDPOINT"
        },
        {
            "path": "ENRICHMENT_APPSERVICE_NAME",
            "env_var": "ENRICHMENT_APPSERVICE_NAME"
        },
        {
            "path": "DEPLOYMENT_KEYVAULT_NAME",
            "env_var": "DEPLOYMENT_KEYVAULT_NAME"
        },
        {
            "path": "MAX_CSV_FILE_SIZE",
            "env_var": "MAX_CSV_FILE_SIZE"
        },
        {
            "path": "SERVICE_MANAGEMENT_REFERENCE",
            "env_var": "SERVICE_MANAGEMENT_REFERENCE"
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

if [ -n "${IN_AUTOMATION}" ]; then
    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ $AZURE_ENVIRONMENT == "AzureUSGovernment" ]]; then
        az cloud set --name AZUReUSGovernment > /dev/null 2>&1
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" > /dev/null 2>&1
    az account set -s "$ARM_SUBSCRIPTION_ID" > /dev/null 2>&1
fi

# Name of your Key Vault
keyVaultName=$(cat inf_output.json | jq -r .DEPLOYMENT_KEYVAULT_NAME.value)
# Names of your secrets
secretNames=("AZURE-SEARCH-SERVICE-KEY" "AZURE-BLOB-STORAGE-KEY" "BLOB-CONNECTION-STRING" "COSMOSDB-KEY" "AZURE-OPENAI-SERVICE-KEY")

# Retrieve and export each secret
for secretName in "${secretNames[@]}"; do
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName --query value -o tsv)
  envVarName=$(echo $secretName | tr '-' '_')
  echo export $envVarName=\'$secretValue\'
done
    