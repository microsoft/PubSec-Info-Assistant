# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import subprocess
import os

BLOB_CONNECTION_STRING = os.environ.get("BLOB_CONNECTION_STRING")
AZURE_SEARCH_SERVICE_ENDPOINT = os.environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
AZURE_SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX")
AZURE_SEARCH_SERVICE_KEY = os.environ.get("AZURE_SEARCH_SERVICE_KEY")
ENRICHMENT_APPSERVICE_NAME = os.environ.get("ENRICHMENT_APPSERVICE_NAME")
AZURE_WEBSITE_DOMAIN = os.environ.get("TF_VAR_azure_websites_domain") or "false"

subprocess.call(['python', 'run_tests.py', '--storage_account_connection_str', BLOB_CONNECTION_STRING, \
    '--search_service_endpoint', AZURE_SEARCH_SERVICE_ENDPOINT, \
    '--search_index', AZURE_SEARCH_INDEX, \
    '--search_key', AZURE_SEARCH_SERVICE_KEY, \
    '--wait_time_seconds', '60', \
    '--file_extensions', 'docx', 'pdf', 'html', 'jpg', 'png', 'csv', 'md', 'pptx', 'txt', 'xlsx', 'xml'])

subprocess.call(['python', 'run_api_tests.py', '--enrichment_service_endpoint', ENRICHMENT_APPSERVICE_NAME, \
    '--azure_websites_domain', AZURE_WEBSITE_DOMAIN])
