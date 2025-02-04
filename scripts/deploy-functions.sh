# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Deploy Azure Functions

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"

# check the Azure CLI version to ensure a supported version that uses AD authentication for the webapp deployment
version=$(az version --output tsv --query '"azure-cli"')
version_parts=(${version//./ })
if [ ${version_parts[0]} -lt 2 ]; then
    echo "Azure CLI version 2.60.0 or higher is required for webapp deployment. Please run 'az upgrade' to upgrade your Azure CLI version."
    exit 1
else
    if [ ${version_parts[0]} -le 2 ] && [ ${version_parts[1]} -lt 60 ]; then
        echo "Azure CLI version 2.60.0 or higher is required for webapp deployment. Please run 'az upgrade' to upgrade your Azure CLI version."
        exit 1
    else
        if [ ${version_parts[0]} -le 2 ] && [ ${version_parts[1]} -le 60 ] && [ ${version_parts[2]} -lt 0 ]; then
            echo "Azure CLI version 2.60.0 or later is required to run this script. Please run 'az upgrade' to upgrade your Azure CLI version."
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

# Build the docker image for the functions
echo "Building the docker image for the functions"
$DIR/../functions/docker-build.sh

# Push the docker image to the container registry
tag=$(cat "$DIR/../functions/image_tag.txt")
echo "Tag for the docker image is $tag"
echo "Pushing the docker image to the container registry"
$DIR/../scripts/push-to-acr.sh -n functionapp -t $tag -f $DIR/../artifacts/functionapp

# Update the function app with the new image
echo "Updating the function webapp with the new image"
az functionapp config container set --name $AZURE_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP_NAME --image ${CONTAINER_REGISTRY}/functionapp:$tag --registry-server "https://${CONTAINER_REGISTRY}" --registry-username $CONTAINER_REGISTRY_USERNAME --registry-password $CONTAINER_REGISTRY_PASSWORD

# Restart the Azure Functions after deployment
az functionapp restart --name $AZURE_FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP_NAME

echo "Functions deployed successfully"
echo -e "\n" 