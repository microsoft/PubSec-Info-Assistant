# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import subprocess
import os

STORAGE_ACCOUNT_URL = os.environ.get("AZURE_BLOB_STORAGE_ENDPOINT")
AZURE_SEARCH_SERVICE_ENDPOINT = os.environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
AZURE_SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX")

subprocess.call(['python', 'run_tests.py', '--storage_account_url', STORAGE_ACCOUNT_URL, \
    '--search_service_endpoint', AZURE_SEARCH_SERVICE_ENDPOINT, \
    '--search_index', AZURE_SEARCH_INDEX, \
    '--wait_time_seconds', '60', \
    '--file_extensions', 'docx', 'pdf', 'html', 'jpg', 'png', 'csv', 'md', 'pptx', 'txt', 'xlsx', 'xml'])