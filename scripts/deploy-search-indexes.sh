# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -x

figlet Search Index

if [ -n "${IN_AUTOMATION}" ]
then

    if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/environments/infrastructure.env"

search_url="${AZURE_SEARCH_SERVICE_ENDPOINT}"

# Get the Search Admin Key
search_key=$(az search admin-key show --resource-group $RESOURCE_GROUP_NAME --service-name $AZURE_SEARCH_SERVICE --query primaryKey -o tsv)
export AZURE_SEARCH_ADMIN_KEY=$search_key

# Create vector index
index_vector_json=$(cat ${DIR}/../azure_search/create_vector_index.json | envsubst | tr -d "\n" | tr -d "\r")
index_vector_name=$(echo $index_vector_json | jq -r .name )
echo "Creating index $index_vector_name ..."
curl -s -X PUT --header "Content-Type: application/json" --header "api-key: $AZURE_SEARCH_ADMIN_KEY" --data "$index_vector_json" $search_url/indexes/$index_vector_name?api-version=2023-07-01-Preview

echo -e "\n"
echo "Successfully deployed $index_vector_name."
