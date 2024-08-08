# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

# This script is here to initialise your Terraform in a given directory
# This allows us to grab variables from a previous Terrform run and also
# simplifies the whole workspace switching.

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#
# Argument parsing
#

function show_usage() {
    echo "terraform-init.sh [DIR]"
    echo
    echo "Initialise terraform in a particular directory"
}

# Process switches:
if [[ $# -eq 1 ]]; then
    TERRAFORM_DIR=$1
else
    show_usage
    exit 1
fi

# We could use the mechanism that Terraform already has to pass in the directory,
# but `WORKSPACE` does not support that
pushd "$TERRAFORM_DIR" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

if [ -n "${IN_AUTOMATION}" ]
then
    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ "$AZURE_ENVIRONMENT" == "AzureUSGovernment" ]]; then
        terraform init -backend-config="resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
        -backend-config="storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
        -backend-config="container_name=$TF_BACKEND_CONTAINER" \
        -backend-config="access_key=$TF_BACKEND_ACCESS_KEY" \
        -backend-config="key=$TF_BACKEND_STATE_KEY" \
        -backend-config="environment=usgovernment"
    else
        terraform init -backend-config="resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
        -backend-config="storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
        -backend-config="container_name=$TF_BACKEND_CONTAINER" \
        -backend-config="access_key=$TF_BACKEND_ACCESS_KEY" \
        -backend-config="key=$TF_BACKEND_STATE_KEY"
    fi
else
    terraform init -upgrade
fi

workspace_exists=$(terraform workspace list | grep -qE "\s${WORKSPACE}$"; echo $?)
if [[ "$workspace_exists" == "0" ]]; then
    terraform workspace select ${WORKSPACE}
else
    terraform workspace new ${WORKSPACE}
fi