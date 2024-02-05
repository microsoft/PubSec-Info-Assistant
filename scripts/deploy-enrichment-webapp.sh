# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Deploy Enrichment Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"

end=`date -u -d "3 years" '+%Y-%m-%dT%H:%MZ'`

cd $BINARIES_OUTPUT_PATH

# check the Azure CLI version to ensure a supported version that uses AD authentication for the webapp deployment
version=$(az version --output tsv --query '"azure-cli"')
version_parts=(${version//./ })
if [ ${version_parts[0]} -lt 2 ]; then
    echo "Azure CLI version 2.48.1 or higher is required for webapp deployment. Please run 'az upgrade' to upgrade your Azure CLI version."
    exit 1
else
    if [ ${version_parts[0]} -le 2 ] && [ ${version_parts[1]} -lt 48 ]; then
        echo "Azure CLI version 2.48.1 or higher is required for webapp deployment. Please run 'az upgrade' to upgrade your Azure CLI version."
        exit 1
    else
        if [ ${version_parts[0]} -le 2 ] && [ ${version_parts[1]} -le 48 ] && [ ${version_parts[2]} -lt 1 ]; then
            echo "Azure CLI version 2.48.1 or later is required to run this script. Please run 'az upgrade' to upgrade your Azure CLI version."
            exit 1
        fi
    fi
    echo "Azure CLI version checked successfully"
fi

if [ -n "${IN_AUTOMATION}" ]
then

    if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# deploy the zip file to the webapp
az webapp deploy --name $ENRICHMENT_APPSERVICE_NAME --resource-group $RESOURCE_GROUP_NAME --type zip --src-path enrichment.zip --clean true --timeout 600000 --verbose

echo "Enrichment Webapp deployed successfully"
echo -e "\n"
