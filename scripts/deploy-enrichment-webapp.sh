#!/bin/bash
set -e

figlet Deploy Enrichment Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"

# Build the docker image for the webapp
echo "Building the docker image for the webapp"
$DIR/../container_images/enrichment_container_image/docker-build.sh

# Tag the Docker image
tag=$(cat "$DIR/../container_images/enrichment_container_image/image_tag.txt")
echo "Tag for the docker image is $tag"

# Push the docker image to the local Docker registry
echo "Pushing the docker image to the local Docker registry"
docker tag enrichmentapp:$tag localhost:5000/enrichmentapp:$tag
docker push localhost:5000/enrichmentapp:$tag

# Deploy the enrichment webapp to Kubernetes
echo "Deploying enrichment webapp to Kubernetes"
kubectl apply -f $DIR/../k8s/enrichment-app-deployment.yaml
kubectl set image deployment/enrichment-app enrichment-app=localhost:5000/enrichmentapp:$tag

# Restart the webapp
kubectl rollout restart deployment/enrichment-app

echo "Enrichment Webapp deployed successfully"
echo -e "\n"
