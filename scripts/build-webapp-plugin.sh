# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Deploy Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"
BACKEND_ROOT_PATH="${DIR}/..//app/backend"

end=`date -u -d "3 years" '+%Y-%m-%dT%H:%MZ'`

cd $BINARIES_OUTPUT_PATH

#Build the AzLib that contains the JavaScript functions that enable the upload feature
cd ${BACKEND_ROOT_PATH}
rm -r plugin
mkdir -p ./plugin
cd ../frontend-plugin
npm install
npm run build

# zip the webapp-viewer content from app/backend to the ./artifacts folders
cd ../backend/plugin
zip -q -r ${BINARIES_OUTPUT_PATH}/webapp-plugin.zip .
cd $DIR
echo "Successfully zipped webapp-plugin"
echo -e "\n"
