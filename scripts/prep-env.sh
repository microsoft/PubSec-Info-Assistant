# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e


# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra" > /dev/null
echo "Current Folder: $(basename "$(pwd)")"
echo "state file: terraform.tfstate.d/${TF_VAR_environmentName}/terraform.tfstate"

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra/"
echo

# Retrieve vars
for var in "${!TF_VAR_@}"; do
    echo "\$TF_VAR_${var#TF_VAR_} = ${!var}"
done

#  Get the new and old envrironment values
FILE_PATH="$DIR/upgrade_repoint.config.json"
old_random_text=$(jq -r '.new_env.random_text' $FILE_PATH)
old_resource_group=$(jq -r '.new_env.resource_group' $FILE_PATH)
subscription=$TF_VAR_subscriptionId
random_text=$old_random_text

echo "subscription: $subscription"
echo "old_random_text: $old_random_text"

user_id=$(az ad signed-in-user show --query id -o tsv)
echo "current user id: $user_id"


# assign roles to the current user
az role assignment create --assignee $user_id --role "Owner" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Cognitive Services OpenAI User" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Search Index Data Contributor" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Search Index Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Storage Blob Data Contributor" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Storage Blob Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group
az role assignment create --assignee $user_id --role "Storage Blob Data Reader" --scope /subscriptions/$subscription/resourceGroups/$old_resource_group

#keyvault role assignment
az keyvault set-policy --name infoasst-kv-$old_random_text --object-id $user_id --secret-permissions Get List