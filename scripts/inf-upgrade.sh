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


# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra/"

echo "TF_VAR_subscriptionId: $TF_VAR_subscriptionId"
echo "TF_VAR_resource_group_name: $TF_VAR_resource_group_name"
echo "TF_VAR_environmentName: $TF_VAR_environmentName"

# Import the existing resources into the Terraform state
terraform import azurerm_resource_group.rg /subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name




