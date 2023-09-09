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
docker push $CONTAINER_REGISTRY_NAME.azurecr.io/enrichment-app:${tag}




# az acr login --name infoasstcr6loek 
# docker push enrichment-app:${tag}

# az acr login --name ${var.container_registry}
# # docker push ${var.container_registry}.azurecr.io/<image_name>:<tag>
# docker push ${var.container_registry}.azurecr.io/enrichment-app:${tag}


# echo $CONTAINER_REGISTRY_PASSWORD | docker login infoasstcr6loek.azurecr.io --username $CONTAINER_REGISTRY_USERNAME --password-stdin
# docker push enrichment-app:${tag}
# docker tag gdal_container ${var.container_registry}/gdal_container:${data.local_file.image_tag.content}
# docker push ${var.container_registry}/gdal_container:${data.local_file.image_tag.content}








echo "Containers deployed successfully"




        # docker login --username ${var.container_registry_admin_username} --password ${var.container_registry_admin_password} ${var.container_registry}
        # docker tag gdal_container ${var.container_registry}/gdal_container:${data.local_file.image_tag.content}
        # docker push ${var.container_registry}/gdal_container:${data.local_file.image_tag.content}




# Note on use of `sudo`
# To avoid docker-in-docker, we're reusing the /var/run/docker.sock socket from the host.
# On the host, permission to access the docker socket is typically controlled by membership
# of the `docker` group. For that to work here, we need the `vscode` user in the dev container
# to be a member of a group with the same group id (GID) as the GID for the `docker` group 
# on the host.
# In a (non-exhaustive) survey of people on the team we found 115, 998, 999, and 1001 as
# values for the GID for the `docker` group.
# As an alternative to keep the portability of the dev container, we are using `sudo` to 
# run elevated when performing docker commands.
# Since the `az acr login` command also manipulates docker, it needs to run elevated as well.
# To support this, the host user's `.azure` folder is mapped in twice, once to /home/vscode/.azure
# and a second time to /root/.azure. This ensures that the CLI can be invoked with or without
# sudo and still pick up the user credentials