# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Unit Tests

# Get the directory that this script is in - move to tests dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd "$DIR/../tests/unit_tests" > /dev/null

# # Get env vars for workspace from Terraform outputs
# source "${DIR}/environments/infrastructure.env"
# source "${DIR}/load-env.sh"

# This is called if we are in a CI system and we will login
# with a Service Principal.
if [ -n "${IN_AUTOMATION}" ]
then
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$AZURE_SUBSCRIPTION_ID"
fi

# Install requirements
pip install -r ../requirements.txt --disable-pip-version-check -q

BASE_PATH=$(realpath "$DIR/..")

# Check active environment
default_env=$(azd env list --output json | jq -r '.[] | select(.IsDefault == true) | .Name')

# Create or set an environment for unit testing : unittesting1
env="unittesting1"
env_list_result=$(azd env list --output json | jq -r '.[].Name')

# Check if the environment already exists
if echo "$env_list_result" | grep -q "^$env$"; then
    # Select the existing environment
    azd env select "$env"
else
    # Create a new environment
    azd env new "$env"
fi

# Pipeline functional test
python test_azd_preprovision.py \
    --azure_subscription_id "${AZURE_SUBSCRIPTION_ID}" \
    --azure_location "${AZURE_LOCATION}" \
    --env "${env}" \

# After running, set the default environment back to the original if it is not null or empty
if [ -n "$default_env" ]; then
    azd env select "$default_env"
fi