# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

source ./scripts/load-env.sh > /dev/null 2>&1

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
            "path": "AZURE_STORAGE_UPLOAD_CONTAINER",
            "env_var": "AZURE_BLOB_STORAGE_UPLOAD_CONTAINER"
        },
        {
            "path": "AZURE_OPENAI_SERVICE",
            "env_var": "AZURE_OPENAI_SERVICE"
        },
        {
            "path": "AZURE_OPENAI_RESOURCE_GROUP",
            "env_var": "AZURE_OPENAI_RESOURCE_GROUP"
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
            "path": "AZURE_SUBSCRIPTION_ID",
            "env_var": "AZURE_SUBSCRIPTION_ID"
        },
        {
            "path": "AZURE_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
        },
        {
            "path": "BLOB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "AZURE_BLOB_STORAGE_ENDPOINT"
        },
        {
            "path": "TARGET_EMBEDDINGS_MODEL",
            "env_var": "TARGET_EMBEDDINGS_MODEL"
        },
        {
            "path": "EMBEDDING_VECTOR_SIZE",
            "env_var": "EMBEDDING_VECTOR_SIZE"
        },
        {
            "path": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME",
            "env_var": "AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME"
        },
        {
            "path": "EMBEDDING_DEPLOYMENT_NAME",
            "env_var": "EMBEDDING_DEPLOYMENT_NAME"
        },
        {
            "path": "USE_AZURE_OPENAI_EMBEDDINGS",
            "env_var": "USE_AZURE_OPENAI_EMBEDDINGS"
        },
        {
            "path": "ENRICHMENT_APPSERVICE_URL",
            "env_var": "ENRICHMENT_APPSERVICE_URL"
        },
        {
            "path": "DEPLOYMENT_KEYVAULT_NAME",
            "env_var": "DEPLOYMENT_KEYVAULT_NAME"
        },
        {
            "path": "AZURE_OPENAI_CHATGPT_MODEL_NAME",
            "env_var": "AZURE_OPENAI_CHATGPT_MODEL_NAME"
        },
        {
            "path": "ENRICHMENT_ENDPOINT",
            "env_var": "ENRICHMENT_ENDPOINT"
        },
        {
            "path": "AZURE_OPENAI_ENDPOINT",
            "env_var": "AZURE_OPENAI_ENDPOINT"
        },
        {
            "path": "BING_SEARCH_ENDPOINT",
            "env_var": "BING_SEARCH_ENDPOINT"
        },
        {
            "path": "BING_SEARCH_KEY",
            "env_var": "BING_SEARCH_KEY"
        },
        {
            "path": "ENABLEE_BING_SAFE_SEARCH",
            "env_var": "ENABLE_BING_SAFE_SEARCH"
        },
        {
            "path": "AZURE_AI_TRANSLATION_DOMAIN",
            "env_var": "AZURE_AI_TRANSLATION_DOMAIN"
        },
        {
            "path": "AZURE_AI_TEXT_ANALYTICS_DOMAIN",
            "env_var": "AZURE_AI_TEXT_ANALYTICS_DOMAIN"
        },
        {
            "path": "AZURE_ARM_MANAGEMENT_API",
            "env_var": "AZURE_ARM_MANAGEMENT_API"
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
    echo "CHAT_WARNING_BANNER_TEXT='$CHAT_WARNING_BANNER_TEXT'"
    echo "APPLICATION_TITLE='$APPLICATION_TITLE'"
    echo "AZURE_OPENAI_AUTHORITY_HOST='$TF_VAR_azure_openai_authority_host'"
    echo "AZURE_OPENAI_CHATGPT_MODEL_NAME='$AZURE_OPENAI_CHATGPT_MODEL_NAME'"
    echo "AZURE_OPENAI_CHATGPT_MODEL_VERSION='$AZURE_OPENAI_CHATGPT_MODEL_VERSION'"
    echo "AZURE_OPENAI_EMBEDDINGS_MODEL_NAME='$AZURE_OPENAI_EMBEDDINGS_MODEL_NAME'"
    echo "AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION='$AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION'"
    echo "ENABLE_BING_SAFE_SEARCH=$ENABLE_BING_SAFE_SEARCH"
    echo "QUERY_TERM_LANGUAGE='$PROMPT_QUERYTERM_LANGUAGE'"
    echo "ENABLE_WEB_CHAT=$ENABLE_WEB_CHAT"
    echo "ENABLE_UNGROUNDED_CHAT=$ENABLE_UNGROUNDED_CHAT"
    echo "ENABLE_MATH_ASSISTANT=$ENABLE_MATH_ASSISTANT"
    echo "ENABLE_TABULAR_DATA_ASSISTANT=$ENABLE_TABULAR_DATA_ASSISTANT"
    echo "ENABLE_MULTIMEDIA=$ENABLE_MULTIMEDIA"

if [ -n "${IN_AUTOMATION}" ]; then
    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ "$AZURE_ENVIRONMENT" == "AzureUSGovernment" ]]; then
        az cloud set --name AzureUSGovernment > /dev/null 2>&1
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" > /dev/null 2>&1
    az account set -s "$ARM_SUBSCRIPTION_ID" > /dev/null 2>&1
fi    

# Name of your Key Vault
keyVaultName=$(cat inf_output.json | jq -r .DEPLOYMENT_KEYVAULT_NAME.value)

# Names of your secrets
secretNames=("AZURE-SEARCH-SERVICE-KEY" "AZURE-BLOB-STORAGE-KEY" "BLOB-CONNECTION-STRING" "COSMOSDB-KEY" "BINGSEARCH-KEY" "AZURE-OPENAI-SERVICE-KEY" "AZURE-CLIENT-SECRET" "ENRICHMENT-KEY")

# Retrieve and export each secret
for secretName in "${secretNames[@]}"; do
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName --query value -o tsv)
  envVarName=$(echo $secretName | tr '-' '_')
  echo $envVarName=\'$secretValue\'
done        