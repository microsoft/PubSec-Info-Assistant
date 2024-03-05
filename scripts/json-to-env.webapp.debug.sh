# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

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
            "path": "azurE_STORAGE_UPLOAD_CONTAINER",
            "env_var": "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"
        },
        {
            "path": "azurE_OPENAI_SERVICE",
            "env_var": "AZURE_OPENAI_SERVICE"
        },
        {
            "path": "azurE_OPENAI_RESOURCE_GROUP",
            "env_var": "AZURE_OPENAI_RESOURCE_GROUP"
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
            "path": "azurE_OPENAI_CHAT_GPT_DEPLOYMENT",
            "env_var": "AZURE_OPENAI_CHATGPT_DEPLOYMENT"
        },
        {
            "path": "azurE_OPENAI_EMBEDDING_DEPLOYMENT_NAME",
            "env_var": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"
        },        
        {
            "path": "azurE_COSMOSDB_URL",
            "env_var": "COSMOSDB_URL"
        },
        {
            "path": "azurE_COSMOSDB_LOG_DATABASE_NAME",
            "env_var": "COSMOSDB_LOG_DATABASE_NAME"
        },
        {
            "path": "azurE_COSMOSDB_LOG_CONTAINER_NAME",
            "env_var": "COSMOSDB_LOG_CONTAINER_NAME"
        },
        {
            "path": "azurE_CLIENT_ID",
            "env_var": "AZURE_CLIENT_ID"
        },
        {
            "path": "azurE_TENANT_ID",
            "env_var": "AZURE_TENANT_ID"
        },
        {
            "path": "azurE_SUBSCRIPTION_ID",
            "env_var": "AZURE_SUBSCRIPTION_ID"
        },
        {
            "path": "azurE_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
        },
        {
            "path": "bloB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "AZURE_BLOB_STORAGE_ENDPOINT"
        },
        {
            "path": "targeT_EMBEDDINGS_MODEL",
            "env_var": "TARGET_EMBEDDINGS_MODEL"
        },
        {
            "path": "embeddinG_VECTOR_SIZE",
            "env_var": "EMBEDDING_VECTOR_SIZE"
        },
        {
            "path": "iS_USGOV_DEPLOYMENT",
            "env_var": "IS_GOV_CLOUD_DEPLOYMENT"
        },
        {
            "path": "azurE_OPENAI_EMBEDDING_DEPLOYMENT_NAME",
            "env_var": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"
        },
        {
            "path": "embeddinG_DEPLOYMENT_NAME",
            "env_var": "EMBEDDING_DEPLOYMENT_NAME"
        },
        {
            "path": "usE_AZURE_OPENAI_EMBEDDINGS",
            "env_var": "USE_AZURE_OPENAI_EMBEDDINGS"
        },
        {
            "path": "enrichmenT_APPSERVICE_NAME",
            "env_var": "ENRICHMENT_APPSERVICE_NAME"
        },
        {
            "path": "deploymenT_KEYVAULT_NAME",
            "env_var": "DEPLOYMENT_KEYVAULT_NAME"
        },
        {
            "path": "azurE_OPENAI_CHATGPT_MODEL_NAME",
            "env_var": "AZURE_OPENAI_CHATGPT_MODEL_NAME"
        },
        {
            "path": "enrichmenT_ENDPOINT",
            "env_var": "ENRICHMENT_ENDPOINT"
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
    map("\(.key)=\"\(.value.value)\"")
    |
    .[]
    ' | sed "s/\"/'/g" # replace double quote with single quote to handle special chars

    echo "EMBEDDINGS_QUEUE='embeddings-queue'"
    echo "DEQUEUE_MESSAGE_BATCH_SIZE=1"
    echo "MAX_EMBEDDING_REQUEUE_COUNT=5"
    echo "EMBEDDING_REQUEUE_BACKOFF=60"
    echo "CHAT_WARNING_BANNER_TEXT='$CHAT_WARNING_BANNER_TEXT'"

if [ -n "${IN_AUTOMATION}" ]
then
    IS_USGOV_DEPLOYMENT=$(jq -r '.properties.outputs.iS_USGOV_DEPLOYMENT.value' infra_output.json)

    if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
        az cloud set --name AzureUSGovernment > /dev/null 2>&1
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" > /dev/null 2>&1
    az account set -s "$ARM_SUBSCRIPTION_ID" > /dev/null 2>&1
fi    

# Name of your Key Vault
keyVaultName=$(cat infra_output.json | jq -r .properties.outputs.deploymenT_KEYVAULT_NAME.value)

# Names of your secrets
secretNames=("AZURE-SEARCH-SERVICE-KEY" "AZURE-BLOB-STORAGE-KEY" "BLOB-CONNECTION-STRING" "COSMOSDB-KEY" "AZURE-OPENAI-SERVICE-KEY" "AZURE-CLIENT-SECRET" "ENRICHMENT-KEY")

# Retrieve and export each secret
for secretName in "${secretNames[@]}"; do
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName --query value -o tsv)
  envVarName=$(echo $secretName | tr '-' '_')
  echo $envVarName=\'$secretValue\'
done        