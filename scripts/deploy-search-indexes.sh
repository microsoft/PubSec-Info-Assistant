#!/bin/bash
set -e

figlet Search Index

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/environments/infrastructure.env"

# Create the search index in Elasticsearch
echo "Creating search index in Elasticsearch"
curl -X PUT "localhost:9200/vector-index" -H 'Content-Type: application/json' -d @${DIR}/../elasticsearch/create_vector_index.json

echo -e "\n"
echo "Successfully deployed vector-index."
