# Copyright (c) DataReason.
### Code for On-Premises Deployment.

#!/bin/bash
set -e

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Build the Docker image with the correct context
echo "Building Docker image: functions"
docker build -t functionapp ${DIR}

# Generate a unique tag for the image
tag=$(date -u +"%Y%m%d-%H%M%S")
echo "Tagging image with: $tag"
docker tag functionapp functionapp:$tag

# Output the tag to a file to be used in deployment
echo -n "$tag" > ${DIR}/image_tag.txt
echo "Build and tagging complete. Tag: $tag"

#Explanation
#Set Script to Exit on Error: Using set -e to ensure the script exits if any command fails.
#Get Script Directory: Getting the directory where the script is located.
#Build Docker Image: Building the Docker image with the context of the current directory.
#Generate Unique Tag: Generating a unique tag for the image based on the current date and time.
#Tag Docker Image: Tagging the Docker image with the generated tag.
#Output Tag to File: Writing the tag to a file for use in deployment.