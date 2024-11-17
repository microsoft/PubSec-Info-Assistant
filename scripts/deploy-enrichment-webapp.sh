# Copyright (c) DataReason.
### Code for On-Premises Deployment.

#!/bin/bash
set -e

figlet Deploy Enrichment Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Build the docker image for the webapp
echo "Building the docker image for the webapp"
$DIR/../functions/docker-build.sh

# Push the docker image to the local Docker registry
tag=$(cat "$DIR/../functions/image_tag.txt")
echo "Tag for the docker image is $tag"
echo "Pushing the docker image to the local Docker registry"
docker tag functionapp:$tag localhost:5000/functionapp:$tag
docker push localhost:5000/functionapp:$tag

# Update the docker-compose file with the new image tag
sed -i "s|functionapp:.*|localhost:5000/functionapp:$tag|g" $DIR/../docker-compose.yml

# Deploy the webapp using docker-compose
echo "Deploying the webapp using docker-compose"
docker-compose -f $DIR/../docker-compose.yml up -d

echo "Enrichment Webapp deployed successfully"

#Explanation:
#Docker Compose: Using Docker Compose for deployment.
#Build Docker Image: Building the Docker image for the webapp.
#Push to Local Registry: Tagging and pushing the Docker image to the local Docker registry.
#Update Docker Compose: Updating the Docker Compose file with the new image tag.
#Deploy Webapp: Deploying the webapp using Docker Compose.