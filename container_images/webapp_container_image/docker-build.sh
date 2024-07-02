# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -eo pipefail

# Build the Docker image with the correct context
echo "Building Docker image: webapp"
echo -e "\n"
sudo docker build -f ./container_images/webapp_container_image/Dockerfile -t webapp . --build-arg BUILDKIT_INLINE_CACHE=1

# Generate a unique tag for the image
tag=$(date -u +"%Y%m%d-%H%M%S")
echo "Tagging image with: $tag"
sudo docker tag webapp webapp:$tag

# Output the tag to a file to be used in deployment
echo -n "$tag" > ./container_images/webapp_container_image/image_tag.txt
echo -e "\n"

# Export docker image to the artifacts folder
echo "Exporting docker image to artifacts folder"
echo -e "\n"
rm -rf ./artifacts/webapp
mkdir -p ./artifacts/webapp
skopeo copy docker-daemon:webapp:$tag oci:./artifacts/webapp

echo "Build and tagging complete. Tag: $tag"
echo -e "\n"