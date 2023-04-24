#!/bin/bash
set -e

figlet Deploy Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../app/backend/"

#cleanup configuration files that will get updated after deployment
if [ -f $BINARIES_OUTPUT_PATH/.azure.config ]
    then
        rm $BINARIES_OUTPUT_PATH/.azure/config
    fi

cd $BINARIES_OUTPUT_PATH
az webapp up -n $AZURE_WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME --subscription $SUBSCRIPTION_ID --runtime "PYTHON:3.10" --os-type Linux