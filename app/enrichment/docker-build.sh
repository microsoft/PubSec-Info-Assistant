# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet "Build Docker Containers"

# Get the required directories of the project
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPTS_DIR="$(realpath "$APP_DIR/../../scripts")"

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#source "${SCRIPTS_DIR}"/load-env.sh
source "${SCRIPTS_DIR}/environments/infrastructure.env"

# Build the container
echo "Building container"
sudo docker build -t enrichment-app ${DIR} --build-arg BUILDKIT_INLINE_CACHE=1
tag=$(date -u +"%Y%m%d-%H%M%S")
sudo docker tag enrichment-app enrichment-app:${tag}
sudo docker tag enrichment-app $CONTAINER_REGISTRY_NAME.azurecr.io/enrichment-app:${tag}

# Deploying to ACR
echo "Deploying containers to ACR"
if [ -n "${IN_AUTOMATION}" ]
then
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi
sudo docker tag enrichment-app $CONTAINER_REGISTRY_NAME.azurecr.io/enrichment-app:${tag}
az acr login --name $CONTAINER_REGISTRY_NAME
docker push $CONTAINER_REGISTRY_NAME.azurecr.io/enrichment-app:${tag}
echo "Containers deployed successfully"