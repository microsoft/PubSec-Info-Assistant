# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/sh

# if [ -n "${FROM_PIPELINE}" ]; then
#     if [ -n "${AZURE_ENVIRONMENT}" ] && [ "$AZURE_ENVIRONMENT" = "AzureUSGovernment" ]; then
#         az cloud set --name AzureUSGovernment 
#     fi

#     az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
#     az account set -s "$AZURE_SUBSCRIPTION_ID"
# fi

search_url="${AZURE_SEARCH_SERVICE_ENDPOINT}"

displayError() {
    if [ "${response#*http_code=}" -ge 400 ]; then
        echo "API Error = $response"
    fi
}

# Obtain an access token for Azure Search
access_token=$(az account get-access-token --resource "$azure_search_scope" --query accessToken -o tsv)

# Create shared data source that can be used across multiple indexes
data_source_json=$(envsubst < ./azure_search/create_data_source.json | tr -d "\n" | tr -d "\r")
data_source_name=$(echo "$data_source_json" | jq -r .name)
echo "Creating data source $data_source_name ..."
response=$(curl -s --show-error -w "http_code=%{http_code}" -X PUT --header "Content-Type: application/json" --header "Authorization: Bearer $access_token" --data "$data_source_json" "$search_url/datasources/$data_source_name?api-version=2024-05-01-preview")
displayError

# Create shared skillset
skillset_json=$(cat ./azure_search/create_skillset.json | envsubst | tr -d "\n" | tr -d "\r")
skillset_name=$(echo "$skillset_json" | jq -r .name)
echo "Creating skillset $skillset_name ..."
response=$(curl -s --show-error -w "http_code=%{http_code}" -X PUT --header "Content-Type: application/json" --header "Authorization: Bearer $access_token" --data "$skillset_json" "$search_url/skillsets/$skillset_name?api-version=2024-05-01-preview")
displayError

# Fetch existing index definition if it exists
index_vector_json=$(cat ./azure_search/create_vector_index.json | envsubst | tr -d "\n" | tr -d "\r")
index_vector_name=$(echo "$index_vector_json" | jq -r .name)
existing_index=$(curl -s --header "Authorization: Bearer $access_token" "$search_url/indexes/$index_vector_name?api-version=2024-05-01-preview")

if echo "$existing_index" | grep -q "No index with the name"; then
    existing_dimensions=$(echo "$existing_index" | jq -r '.fields | map(select(.name == "contentVector")) | .[0].dimensions')
    existing_index_name=$(echo "$existing_index" | jq -r '.name')
    # Compare existing dimensions with current $EMBEDDING_VECTOR_SIZE
    if [ -n "$existing_dimensions" ] && [ "$existing_dimensions" != "$EMBEDDING_VECTOR_SIZE" ]; then
        echo "Dimensions mismatch: Existing dimensions: $existing_dimensions, Current dimensions: $EMBEDDING_VECTOR_SIZE"
        echo "Do you want to continue? This will delete the existing index and data! (y/n) \c"
        read use_existing
        case "$use_existing" in
            [Yy]*)
                echo "Deleting the existing index $existing_index_name..."
                curl -X DELETE --header "Authorization: Bearer $access_token" "$search_url/indexes/$existing_index_name?api-version=2024-05-01-preview"
                echo "Index $index_vector_name deleted."
                ;;
            *)
                echo "Operation aborted by the user."
                exit 0
                ;;
        esac
    fi
fi

# Create vector index
echo "Creating index $index_vector_name ..."
response=$(curl -s --show-error -w "http_code=%{http_code}" -X PUT --header "Content-Type: application/json" --header "Authorization: Bearer $access_token" --data "$index_vector_json" "$search_url/indexes/$index_vector_name?api-version=2024-05-01-preview")
displayError

# Create all files indexer
indexer_json=$(cat ./azure_search/create_indexer.json | envsubst | tr -d "\n" | tr -d "\r")
indexer_name=$(echo "$indexer_json" | jq -r .name)
echo "Creating indexer $indexer_name ..."
response=$(curl -s --show-error -w "http_code=%{http_code}" -X PUT --header "Content-Type: application/json" --header "Authorization: Bearer $access_token" --data "$indexer_json" "$search_url/indexers/$indexer_name?api-version=2024-05-01-preview")
displayError

echo "\n"
echo "Successfully deployed $index_vector_name."
