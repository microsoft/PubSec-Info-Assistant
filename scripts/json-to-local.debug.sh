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
            "path": "xY_ROUNDING_FACTOR",
            "env_var": "XY_ROUNDING_FACTOR"
        },
        {
            "path": "chunK_TARGET_SIZE",
            "env_var": "CHUNK_TARGET_SIZE"
        },
        {
            "path": "reaL_WORDS_TARGET",
            "env_var": "REAL_WORDS_TARGET"
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
            "path": "pdfpollingqueue",
            "env_var": "PDF_POLLING_QUEUE"
        },
        {
            "path": "pdfsubmitqueue",
            "env_var": "PDF_SUBMIT_QUEUE"
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