# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

ENV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export ARM_ENVIRONMENT=public

#setting up necessary permissions to access the Docker daemon socket
sudo chmod 666 /var/run/docker.sock

#Ensure hw time sync is enabled to avoid time drift when the host OS sleeps. 
#Time sync is required else Azure authentication tokens will be invalid
source "${ENV_DIR}/time-sync.sh"

# Default values - you can override these in your environment.env
# -------------------------------------------------------------------------------------------------------
# subscription name passed in from pipeline - if not, use 'local'
if [ -z "$ENVIRONMENT_NAME" ]; then
    export ENVIRONMENT_NAME="local"
fi

echo "Environment set: $ENVIRONMENT_NAME."

if [[ -n $TF_IN_AUTOMATION ]]; then

    if [[ -z $BUILD_BUILDID ]]; then
        echo "Require BUILD_BUILDID to be set for CI builds"
        exit 1        
    fi    
    export TF_VAR_build_number=$BUILD_BUILDNUMBER
fi

# Override in local.env if you want to disable cleaning functional test data
export DISABLE_TEST_CLEANUP=false
export IGNORE_TEST_PIPELINE_QUERY=false

export NOTEBOOK_CONFIG_OVERRIDE_FOLDER="default"

# Pull in variables dependent on the environment we are deploying to.
if [ -f "$ENV_DIR/environments/$ENVIRONMENT_NAME.env" ]; then
    echo "Loading environment variables for $ENVIRONMENT_NAME."
    source "$ENV_DIR/environments/$ENVIRONMENT_NAME.env"
fi

# Pull in variables dependent on the Language being targeted
if [ -f "$ENV_DIR/environments/languages/$DEFAULT_LANGUAGE.env" ]; then
    echo "Loading environment variables for Language: $DEFAULT_LANGUAGE."
    source "$ENV_DIR/environments/languages/$DEFAULT_LANGUAGE.env"
else
    echo "No Language set, please check local.env.example for DEFAULT_LANGUAGE"
    exit 1
fi

# Pull in variables dependent on the Azure Environment being targeted
if [ -f "$ENV_DIR/environments/AzureEnvironments/$AZURE_ENVIRONMENT.env" ]; then
    echo "Loading environment variables for Azure Environment: $AZURE_ENVIRONMENT."
    source "$ENV_DIR/environments/AzureEnvironments/$AZURE_ENVIRONMENT.env"
else
    echo "No Azure Environment set, please check local.env.example for AZURE_ENVIRONMENT"
    exit 1
fi

# Fail if the following environment variables are not set
if [[ -z $WORKSPACE ]]; then
    echo "WORKSPACE must be set."
    exit 1
elif [[ "${WORKSPACE}" =~ [[:upper:]] ]]; then
    echo "Please use a lowercase workspace environment variable between 1-15 characters. Please check 'private.env.example'"
    exit 1
fi

# Set the name of the resource group
export TF_VAR_resource_group_name="infoasst-$WORKSPACE"

# The default key that is used in the remote state
export TF_BACKEND_STATE_KEY="shared.infoasst.tfstate"

echo -e "\n\e[32m🎯 Target Resource Group: \e[33m$TF_VAR_resource_group_name\e[0m\n"