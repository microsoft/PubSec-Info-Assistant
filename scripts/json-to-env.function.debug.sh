# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

source ./scripts/load-env.sh > /dev/null 2>&1

if [ -n "${IN_AUTOMATION}" ]; then
    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ $AZURE_ENVIRONMENT == "AzureUSGovernment" ]]; then
        az cloud set --name AzureUSGovernment > /dev/null 2>&1
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" > /dev/null 2>&1
    az account set -s "$ARM_SUBSCRIPTION_ID" > /dev/null 2>&1
fi

secrets="{"
# Name of your Key Vault
keyVaultName=$(cat inf_output.json | jq -r .DEPLOYMENT_KEYVAULT_NAME.value)

# Names of your secrets
secretNames=("AZURE-SEARCH-SERVICE-KEY" "AZURE-BLOB-STORAGE-KEY" "BLOB-CONNECTION-STRING" "COSMOSDB-KEY" "AZURE-FORM-RECOGNIZER-KEY" "ENRICHMENT-KEY")
azWebJobSecretName="BLOB-CONNECTION-STRING"
azWebJobVarName="AzureWebJobsStorage"

# Retrieve and export each secret
for secretName in "${secretNames[@]}"; do
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName --query value -o tsv)
  envVarName=$(echo $secretName | tr '-' '_')
  secrets+="\"$envVarName\": \"$secretValue\","

  if [ "$secretName" == "$azWebJobSecretName" ]; then
    export $azWebJobVarName=$secretValue
    secrets+="\"$azWebJobVarName\": \"$secretValue\","
  fi
done 
secrets=${secrets%?} # Remove the trailing comma
secrets+="}"
secrets="${secrets%,}"

jq -r --arg secrets "$secrets" '
        [
        {
            "path": "AZURE_STORAGE_ACCOUNT",
            "env_var": "BLOB_STORAGE_ACCOUNT"
        },
        {
            "path": "AZURE_BLOB_DROP_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
        },
        {
            "path": "AZURE_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
        },
        {
            "path": "AZURE_BLOB_LOG_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"
        },
        {
            "path": "CHUNK_TARGET_SIZE",
            "env_var": "CHUNK_TARGET_SIZE"
        },
        {
            "path": "FR_API_VERSION",
            "env_var": "FR_API_VERSION"
        },
        {
            "path": "TARGET_PAGES",
            "env_var": "TARGET_PAGES"
        },
        {
            "path": "AZURE_FORM_RECOGNIZER_ENDPOINT",
            "env_var": "AZURE_FORM_RECOGNIZER_ENDPOINT"
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
            "path": "AzureWebJobsStorage",
            "env_var": "AzureWebJobsStorage"
        },
        {
            "path": "ENRICHMENT_ENDPOINT",
            "env_var": "ENRICHMENT_ENDPOINT"
        },
        {
            "path": "ENRICHMENT_NAME",
            "env_var": "ENRICHMENT_NAME"
        },
        {
            "path": "TARGET_TRANSLATION_LANGUAGE",
            "env_var": "TARGET_TRANSLATION_LANGUAGE"
        },
        {
            "path": "ENABLE_DEV_CODE",
            "env_var": "ENABLE_DEV_CODE"
        },
        {
            "path": "BLOB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "BLOB_STORAGE_ACCOUNT_ENDPOINT"
        },
        {
            "path": "AZURE_LOCATION",
            "env_var": "ENRICHMENT_LOCATION"
        },
        {
            "path": "AZURE_SEARCH_INDEX",
            "env_var": "AZURE_SEARCH_INDEX"
        },
        {
            "path": "AZURE_SEARCH_SERVICE_ENDPOINT",
            "env_var": "AZURE_SEARCH_SERVICE_ENDPOINT"
        },
        {
            "path": "DEPLOYMENT_KEYVAULT_NAME",
            "env_var": "DEPLOYMENT_KEYVAULT_NAME"
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
        map({key: .key, value: .value.value})
        |
        reduce .[] as $item ({}; .[$item.key] = $item.value)
        |
    {"IsEncrypted": false, "Values": (. + {"FUNCTIONS_WORKER_RUNTIME": "python", 
            "AzureWebJobs.parse_html_w_form_rec.Disabled": "true", 
            "MAX_SECONDS_HIDE_ON_UPLOAD": "30", 
            "MAX_SUBMIT_REQUEUE_COUNT": "10",
            "POLL_QUEUE_SUBMIT_BACKOFF": "60",
            "PDF_SUBMIT_QUEUE_BACKOFF": "60",
            "MAX_POLLING_REQUEUE_COUNT": "10",
            "SUBMIT_REQUEUE_HIDE_SECONDS": "1200",
            "POLLING_BACKOFF": "30",
            "MAX_READ_ATTEMPTS": "5",
            "MAX_ENRICHMENT_REQUEUE_COUNT": "10",
            "ENRICHMENT_BACKOFF": "60",
            "EMBEDDINGS_QUEUE": "embeddings-queue",
            "MEDIA_SUBMIT_QUEUE": "media-submit-queue",
            "NON_PDF_SUBMIT_QUEUE": "non-pdf-submit-queue",
            "PDF_POLLING_QUEUE": "pdf-polling-queue",
            "PDF_SUBMIT_QUEUE": "pdf-submit-queue",
            "EMBEDDINGS_QUEUE": "embeddings-queue",
            "TEXT_ENRICHMENT_QUEUE": "text-enrichment-queue",
            "IMAGE_ENRICHMENT_QUEUE": "image-enrichment-queue",
            } + ($secrets | fromjson)
             
    )}
    '