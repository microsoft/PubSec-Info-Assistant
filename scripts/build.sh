# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Build

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"
WEBAPP_ROOT_PATH="${DIR}/..//app/frontend"
FUNCTIONS_ROOT_PATH="${DIR}/../functions"
ENRICHMENT_ROOT_PATH="${DIR}/..//app/enrichment"

# reset the current directory on exit using a trap so that the directory is reset even on error
#function finish {
#  popd > /dev/null
#}
#trap finish EXIT

# Clean previous runs on a dev machine
rm -rf ${BINARIES_OUTPUT_PATH} && mkdir -p ${BINARIES_OUTPUT_PATH}

#Build the AzLib that contains the JavaScript functions that enable the upload feature
cd app/frontend
npm install
npm run build

# copy the shared_code files from functions to the webapp
cd ../backend
mkdir -p ./shared_code
cp  ../../functions/shared_code/status_log.py ./shared_code
cp  ../../functions/shared_code/__init__.py ./shared_code

# zip the webapp content from app/backend to the ./artifacts folders
zip -q -r ${BINARIES_OUTPUT_PATH}/webapp.zip .
cd $DIR
echo "Successfully zipped webapp"
echo -e "\n"

# Build the Azure Functions
cd ${FUNCTIONS_ROOT_PATH}
zip -q -r ${BINARIES_OUTPUT_PATH}/functions.zip .
echo "Successfully zipped functions"
echo -e "\n"

# zip the enrichment app content from app/enrichments to the .artifacts folders
cd ${ENRICHMENT_ROOT_PATH}
mkdir -p ./shared_code
cp  ../../functions/shared_code/status_log.py ./shared_code
cp  ../../functions/shared_code/utilities_helper.py ./shared_code
zip -q -r ${BINARIES_OUTPUT_PATH}/enrichment.zip . -x "models/*" @
echo "Successfully zipped enrichment app"
echo -e "\n"