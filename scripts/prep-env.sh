# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
pushd "$DIR/../infra" > /dev/null
echo "Current Folder: $(basename "$(pwd)")"

#  Get the new and old envrironment values
FILE_PATH="$DIR/upgrade_repoint.config.json"
old_random_text=$(jq -r '.new_env.random_text' $FILE_PATH)
old_random_text=$(echo "$old_random_text" | tr '[:upper:]' '[:lower:]')
old_resource_group=$(jq -r '.new_env.resource_group' $FILE_PATH)

subscription=$(az account show --query id  -o tsv)
user_id=$(az ad signed-in-user show --query id -o tsv)
user_name=$(az ad signed-in-user show --query userPrincipalName)

echo "subscription: $subscription"
echo "old_random_text: $old_random_text"
echo "current user id: $user_id"
echo "user_name: $user_name"

# assign roles to the current user
az role assignment create --assignee $user_id --role "Owner" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Cognitive Services OpenAI User" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Search Index Data Contributor" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Search Index Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Storage Blob Data Contributor" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Storage Blob Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
# az role assignment create --assignee $user_id --role "Storage Blob Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group

# keyvault role assignment
az keyvault set-policy --name infoasst-kv-$old_random_text --object-id $user_id --secret-permissions Get List

# assign access requirements to various apps
enrichment_appName="infoasst-enrichmentweb-$old_random_text"
web_appName="infoasst-web-$old_random_text"
function_appName="infoasst-func-$old_random_text"

APP_ID=$(az functionapp show --name $function_appName --resource-group $old_resource_group --query "id" --output tsv)
az role assignment create --assignee "$user_id" --role "Owner" --scope "$APP_ID"

APP_ID=$(az webapp show --name $web_appName --resource-group $old_resource_group --query "id" --output tsv)
az role assignment create --assignee "$user_id" --role "Owner" --scope "$APP_ID"

APP_ID=$(az webapp show --name $enrichment_appName --resource-group $old_resource_group --query "id" --output tsv)
az role assignment create --assignee "$user_id" --role "Owner" --scope "$APP_ID"
