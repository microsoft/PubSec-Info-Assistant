#!/bin/bash
set -eo pipefail

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"

# Ensure necessary environment variables are set
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "SUBSCRIPTION_ID is not set. Please set it in load-env.sh or local.env."
    exit 1
fi

if [ -z "$WORKSPACE" ]; then
    echo "WORKSPACE is not set. Please set it in load-env.sh or local.env."
    exit 1
fi

# Set Azure resource group based on the WORKSPACE environment variable
RESOURCE_GROUP="infoasst-${WORKSPACE}"

# Fetch ACR details dynamically
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query "loginServer" -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

DOCKER_HOST="localhost:2375"
DOCKER_API_VERSION="v1.41"

# Function to build Docker images using Docker's REST API
build_docker_image() {
    local image_name=$1
    local dockerfile_path=$2
    local context_dir=$3

    figlet Building Docker $image_name

    echo "Building Docker image: $image_name"
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --unix-socket /var/run/docker.sock \
        "http://${DOCKER_HOST}/build?t=${image_name}&dockerfile=${dockerfile_path}" \
        -d "{\"context\": \"${context_dir}\", \"buildargs\": {\"BUILDKIT_INLINE_CACHE\": \"1\"}}")

    echo "Docker API response: $response"

    if [[ $response == *"error"* ]]; then
        echo "Failed to build Docker image: $image_name"
        echo "Error: $response"
        exit 1
    fi

    echo "Docker image $image_name built successfully"
}

# Function to push Docker images to ACR using Docker CLI
push_to_acr() {
    local image_name=$1
    local acr_image_name="${ACR_LOGIN_SERVER}/${image_name}:latest"
    figlet Pushing $image_name to ACR

    echo "Tagging image $image_name as $acr_image_name"
    docker tag $image_name $acr_image_name

    echo "Pushing image $acr_image_name to ACR"
    printf "%s" $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER --username $ACR_USERNAME --password-stdin
    docker push $acr_image_name

    if [ $? -ne 0 ]; then
        echo "Failed to push Docker image: $acr_image_name"
        exit 1
    fi

    echo "Docker image $acr_image_name pushed to ACR successfully"
}

# Build and push functionapp image
build_docker_image "functionapp" "./functions/Dockerfile" "./functions"
push_to_acr "functionapp"

# Build and push webapp image
build_docker_image "webapp" "./container_images/webapp_container_image/Dockerfile" "./container_images/webapp_container_image"
push_to_acr "webapp"

# Build and push enrichmentapp image
build_docker_image "enrichmentapp" "./container_images/enrichment_container_image/Dockerfile" "./container_images/enrichment_container_image"
push_to_acr "enrichmentapp"

echo "All images built and pushed successfully"