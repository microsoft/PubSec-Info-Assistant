#!/bin/bash
set -e

figlet Deploy Functions

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"

# Build the docker image for the functions
echo "Building the docker image for the functions"
$DIR/../functions/docker-build.sh

# Tag the Docker image
tag=$(cat "$DIR/../functions/image_tag.txt")
echo "Tag for the docker image is $tag"

# Push the docker image to the local Docker registry
echo "Pushing the docker image to the local Docker registry"
docker tag functionapp:$tag localhost:5000/functionapp:$tag
docker push localhost:5000/functionapp:$tag

# Deploy the functions app to Kubernetes
echo "Deploying functions app to Kubernetes"
kubectl apply -f $DIR/../k8s/functions-app-deployment.yaml
kubectl set image deployment/functions-app functions-app=localhost:5000/functionapp:$tag

# Restart the functions app
kubectl rollout restart deployment/functions-app

echo "Functions deployed successfully"
echo -e "\n"
