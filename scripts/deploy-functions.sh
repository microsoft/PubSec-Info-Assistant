# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Deploy Azure Functions

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"

cd $BINARIES_OUTPUT_PATH

if [ -n "${IN_AUTOMATION}" ]
then
    
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# deploy the zip file to the webapp
az functionapp deploy --resource-group $RESOURCE_GROUP_NAME --name $AZURE_FUNCTION_APP_NAME --src-path functions.zip --type zip --async true --verbose

echo "Functions deployed successfully"
