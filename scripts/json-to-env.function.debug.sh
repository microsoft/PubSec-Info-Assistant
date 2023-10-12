# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

jq -r  '
    .properties.outputs |
    [
        {
            "path": "azurE_STORAGE_ACCOUNT",
            "env_var": "BLOB_STORAGE_ACCOUNT"
        },
        {
            "path": "azurE_BLOB_DROP_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
        },
        {
            "path": "azurE_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
        },
        {
            "path": "azurE_STORAGE_KEY",
            "env_var": "BLOB_STORAGE_ACCOUNT_KEY"
        },
        {
            "path": "azurE_BLOB_LOG_STORAGE_CONTAINER",
            "env_var": "BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"
        },
        {
            "path": "chunK_TARGET_SIZE",
            "env_var": "CHUNK_TARGET_SIZE"
        },
        {
            "path": "fR_API_VERSION",
            "env_var": "FR_API_VERSION"
        },
        {
            "path": "targeT_PAGES",
            "env_var": "TARGET_PAGES"
        },
        {
            "path": "azurE_FORM_RECOGNIZER_ENDPOINT",
            "env_var": "AZURE_FORM_RECOGNIZER_ENDPOINT"
        },
        {
            "path": "azurE_FORM_RECOGNIZER_KEY",
            "env_var": "AZURE_FORM_RECOGNIZER_KEY"
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
            "path": "bloB_CONNECTION_STRING",
            "env_var": "BLOB_CONNECTION_STRING"
        },
        {
            "path": "azureWebJobsStorage",
            "env_var": "AzureWebJobsStorage"
        },
        {
            "path": "enrichmenT_KEY",
            "env_var": "ENRICHMENT_KEY"
        },
        {
            "path": "enrichmenT_ENDPOINT",
            "env_var": "ENRICHMENT_ENDPOINT"
        },
        {
            "path": "enrichmenT_NAME",
            "env_var": "ENRICHMENT_NAME"
        },
        {
            "path": "targeT_TRANSLATION_LANGUAGE",
            "env_var": "TARGET_TRANSLATION_LANGUAGE"
        },
        {
            "path": "enablE_DEV_CODE",
            "env_var": "ENABLE_DEV_CODE"
        },
        {
            "path": "azurE_STORAGE_KEY",
            "env_var": "AZURE_BLOB_STORAGE_KEY"
        },
        {
            "path": "bloB_STORAGE_ACCOUNT_ENDPOINT",
            "env_var": "BLOB_STORAGE_ACCOUNT_ENDPOINT"
        },
        {
            "path": "azurE_LOCATION",
            "env_var": "ENRICHMENT_LOCATION"
        },
        {
            "path": "azurE_SEARCH_INDEX",
            "env_var": "AZURE_SEARCH_INDEX"
        },
        {
            "path": "azurE_SEARCH_SERVICE_ENDPOINT",
            "env_var": "AZURE_SEARCH_SERVICE_ENDPOINT"
        },
        {
            "path": "azurE_SEARCH_KEY",
            "env_var": "AZURE_SEARCH_SERVICE_KEY"
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
            "IMAGE_ENRICHMENT_QUEUE": "image-enrichment-queue"
            })}
    '