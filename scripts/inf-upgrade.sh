# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Upgrade

# Reusable functions
import_resource_if_needed() {
    local module_path=$1
    local resource_id=$2

    # Check if the resource is already managed by Terraform
    if terraform state list "$module_path" | grep -q "$module_path"; then
        echo "Resource $module_path is already managed by Terraform"
    else
        echo "Importing $module_path"
        terraform import "$module_path" "$resource_id"
    fi
}


# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra" > /dev/null

echo "Current Folder: $(basename "$(pwd)")"
echo "state file: terraform.tfstate.d/${TF_VAR_environmentName}/terraform.tfstate"
# Initialise Terraform with the correct path and clean up prior tries
# ${DIR}/terraform-init.sh "$DIR/../infra/"
[ -f ".terraform.lock.hcl" ] && rm ".terraform.lock.hcl"
[ -f "terraform.tfstate.d/$TF_VAR_environmentName/terraform.tfstate" ] && rm -r "terraform.tfstate.d/$TF_VAR_environmentName/terraform.tfstate"
terraform init -upgrade

echo
# Retrieve vars
for var in "${!TF_VAR_@}"; do
    echo "\$TF_VAR_${var#TF_VAR_} = ${!var}"
done

# Read randmom text suffix
file_path=".state/$TF_VAR_environmentName/random.txt"
if [ -f "$file_path" ]; then
    random_text=$(<"$file_path")
    random_text=$(echo "$random_text" | tr '[:upper:]' '[:lower:]')
    echo "rendom text suffix: $random_text"
else
    echo "Error: File '$TF_VAR_environmentName' not found."
fi


# Import the existing resources into the Terraform state

# Resource Group
echo
echo -e "\e[1;32m Resource Group \e[0m"
resourceId="/subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name"
import_resource_if_needed "module.storage.azurerm_storage_account.storage" "$resourceId"


# Storage
echo
echo -e "\e[1;32m Storage \e[0m"
export TF_VAR_keyVaultId="infoasst-kv-$random_text"
export TF_VAR_name="infoasststore$random_text"
resourceId="/subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name"
import_resource_if_needed "module.storage.azurerm_storage_account.storage" "$resourceId"








# STUFF
#terraform import module.storage.azurerm_storage_account.storage /subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name