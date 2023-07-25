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
            "path": "nonpdfsubmitqueue",
            "env_var": "NON_PDF_SUBMIT_QUEUE"
        },
        {
            "path": "mediasubmitqueue",
            "env_var": "MEDIA_SUBMIT_QUEUE"
        },
        {
            "path": "pdfpollingqueue",
            "env_var": "PDF_POLLING_QUEUE"
        },
        {
            "path": "pdfsubmitqueue",
            "env_var": "PDF_SUBMIT_QUEUE"
        },
        {
            "path": "maX_SECONDS_HIDE_ON_UPLOAD",
            "env_var": "MAX_SECONDS_HIDE_ON_UPLOAD"
        },
        {
            "path": "maX_SUBMIT_REQUEUE_COUNT",
            "env_var": "MAX_SUBMIT_REQUEUE_COUNT"
        },
        {
            "path": "polL_QUEUE_SUBMIT_BACKOFF",
            "env_var": "POLL_QUEUE_SUBMIT_BACKOFF"
        },
        {
            "path": "pdF_SUBMIT_QUEUE_BACKOFF",
            "env_var": "PDF_SUBMIT_QUEUE_BACKOFF"
        },
        {
            "path": "maX_POLLING_REQUEUE_COUNT",
            "env_var": "MAX_POLLING_REQUEUE_COUNT"
        },
        {
            "path": "submiT_REQUEUE_HIDE_SECONDS",
            "env_var": "SUBMIT_REQUEUE_HIDE_SECONDS"
        },
        {
            "path": "pollinG_BACKOFF",
            "env_var": "POLLING_BACKOFF"
        },
        {
            "path": "maX_READ_ATTEMPTS",
            "env_var": "MAX_READ_ATTEMPTS"
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
    {"IsEncrypted": false, "Values": (. + {"FUNCTIONS_WORKER_RUNTIME": "python", "AzureWebJobs.parse_html_w_form_rec.Disabled": "true"})}
    '