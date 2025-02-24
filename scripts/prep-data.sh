#!/bin/bash

set -e

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/environments/infrastructure.env"

# load env vars
source "${DIR}/load-env.sh"

figlet Prep Data

pip install -r $DIR/requirements.txt

echo "$DIR/../data"
python $DIR/load-test-data-direct-to-index.py "$DIR/../data/*" --storageaccount $AZURE_BLOB_STORAGE_ENDPOINT --uploadcontainer upload --chunkcontainer content  --searchservice $AZURE_SEARCH_SERVICE_ENDPOINT --index $AZURE_SEARCH_INDEX --openaiservice "https://$AZURE_OPENAI_SERVICE.$TF_VAR_azure_openai_domain" --model $AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME -v