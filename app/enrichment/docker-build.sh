# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet "Build/Deploy Containers"

image_name="enrichment-app"

# Get the required directories of the project
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTS_DIR="$(realpath "$APP_DIR/../../scripts")"

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${SCRIPTS_DIR}/load-env.sh"
source "${SCRIPTS_DIR}/environments/infrastructure.env"

# Determine if this is a gov deployment
CONTAINER_REGISTRY_NAME_SUFFIX="azurecr.io"
if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
  CONTAINER_REGISTRY_NAME_SUFFIX="azurecr.us"
fi

# Copy over shared_code to the app directory
echo "Copying shared code"
mkdir -p ${APP_DIR}/shared_code
cp ${APP_DIR}/../../functions/shared_code/status_log.py ${APP_DIR}/shared_code
cp ${APP_DIR}/../../functions/shared_code/utilities_helper.py ${APP_DIR}/shared_code


# Build the container
echo "Building container"
sudo docker build -t ${image_name} ${DIR} --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg MODEL_NAMES=${SENTENCE_TRANSFORMER_EMBEDDING_MODEL}
tag=$(date -u +"%Y%m%d-%H%M%S")
sudo docker tag ${image_name} ${image_name}:${tag}
sudo docker tag ${image_name} $CONTAINER_REGISTRY_NAME.$CONTAINER_REGISTRY_NAME_SUFFIX/${image_name}:${tag}

# Deploying image to ACR
echo "Deploying containers to ACR"
if [ -n "${IN_AUTOMATION}" ]
then
    if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

sudo docker tag ${image_name} $CONTAINER_REGISTRY_NAME.$CONTAINER_REGISTRY_NAME_SUFFIX/${image_name}:${tag}
az acr login --name $CONTAINER_REGISTRY_NAME
docker push $CONTAINER_REGISTRY_NAME.$CONTAINER_REGISTRY_NAME_SUFFIX/${image_name}:${tag}
echo "Containers deployed successfully"

# Configure the webapp to use the ACR image
echo "Pushing container to the WebApp"
status=$(az webapp config container set --name $CONTAINER_APP_SERVICE --resource-group $RESOURCE_GROUP_NAME --docker-custom-image-name $CONTAINER_REGISTRY_NAME.$CONTAINER_REGISTRY_NAME_SUFFIX/$image_name:${tag})
az webapp restart --name $CONTAINER_APP_SERVICE --resource-group $RESOURCE_GROUP_NAME