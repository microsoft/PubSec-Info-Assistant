# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# PAUSE TO ALLOW FOR MANUAL SETUP OF VPN
if [[ "$SECURE_MODE" == "true" ]]; then
    echo "Let's now establish a connection from the client machine to a new virtual network."
    echo -e "Please configure your virtual network\n"
    while true; do
        read -p "Are you ready to continue (y/n)? " yn
        case $yn in
            [Yy]* ) 
                echo "Continuing with the deployment..."
                break;;  
            [Nn]* ) 
                echo "Exiting. Please configure your virtual network settings before continuing."
                exit 1;;  
            * ) 
                echo "Invalid input. Please answer yes (y) or no (n).";;
        esac
    done
fi

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

    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ $AZURE_ENVIRONMENT == "AzureUSGovernment" ]]; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# deploy the zip file to the webapp
az webapp deploy --name $ENRICHMENT_APPSERVICE_NAME --resource-group $RESOURCE_GROUP_NAME --type zip --src-path enrichment.zip --async true --timeout 600000 --verbose

echo "Enrichment Webapp deployed successfully"
echo -e "\n" 
