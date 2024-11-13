#!/bin/bash
set -e

figlet Deploy Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"

# Build the docker image for the webapp
echo "Building the docker image for the webapp"
$DIR/../container_images/webapp_container_image/docker-build.sh

# Tag the Docker image
tag=$(cat "$DIR/../container_images/webapp_container_image/image_tag.txt")
echo "Tag for the docker image is $tag"

# Push the docker image to the local Docker registry
echo "Pushing the docker image to the local Docker registry"
docker tag webapp:$tag localhost:5000/webapp:$tag
docker push localhost:5000/webapp:$tag

# Deploy the webapp to Kubernetes
echo "Deploying webapp to Kubernetes"
kubectl apply -f $DIR/../k8s/webapp-deployment.yaml
kubectl set image deployment/webapp webapp=localhost:5000/webapp:$tag

# Restart the webapp
kubectl rollout restart deployment/webapp

echo "Webapp deployed successfully"
echo -e "\n"
