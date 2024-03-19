# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Upgrade

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
for var in "${!TF_VAR_@}"; do
    echo "\$TF_VAR_${var#TF_VAR_} = ${!var}"
done
echo


# # Import the existing resources into the Terraform state
#terraform import azurerm_resource_group.rg /subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name

# Storage
export TF_VAR_keyVaultId="infoasst-kv-$TF_VAR_environmentName"
export TF_VAR_name="infoasststor$TF_VAR_environmentName"
terraform import module.storage.azurerm_storage_account.storage /subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name
#terraform -chdir=core/storage import azurerm_storage_account.storage /subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name



