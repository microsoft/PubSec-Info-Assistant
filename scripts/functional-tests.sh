# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e


if [ "$FROM_PIPELINE" = "false" ]; then
    figlet Functional Tests
fi

python --version

# Get the directory that this script is in - move to tests dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$DIR/../tests" > /dev/null

eval $(azd env get-values | sed 's/^/export /')


# Install requirements
pip install -r requirements-dev.txt --disable-pip-version-check -q

BASE_PATH=$(realpath "$DIR/..")

# Pipeline functional test
python run_tests.py \
    --storage_account_url "${AZURE_BLOB_STORAGE_ENDPOINT}" \
    --search_service_endpoint "${AZURE_SEARCH_SERVICE_ENDPOINT}" \
    --search_index "${AZURE_SEARCH_INDEX}" \
    --wait_time_seconds 60 \
    --file_extensions "docx" "pdf" "html" "jpg" "png" "csv" "md" "pptx" "txt" "xlsx" "xml"
