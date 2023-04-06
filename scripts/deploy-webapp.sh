#!/bin/bash
set -e

figlet Deploy Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../app/backend/"

#results=$(az webapp config appsettings set --resource-group $RESOURCE_GROUP_NAME --name $AZURE_WEBAPP_NAME --settings AZURE_BLOB_STORAGE_ACCOUNT=$AZURE_BLOB_STORAGE_ACCOUNT AZURE_BLOB_STORAGE_CONTAINER=$AZURE_BLOB_STORAGE_CONTAINER AZURE_SEARCH_SERVICE=$AZURE_SEARCH_SERVICE AZURE_SEARCH_INDEX=$AZURE_SEARCH_INDEX AZURE_OPENAI_SERVICE=$AZURE_OPENAI_SERVICE_NAME AZURE_OPENAI_GPT_DEPLOYMENT=$GPT_MODEL_DEPLOYMENT_NAME AZURE_OPENAI_CHATGPT_DEPLOYMENT=$CHATGPT_MODEL_DEPLOYMENT_NAME)

cd $BINARIES_OUTPUT_PATH
az webapp up -n $AZURE_WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME --subscription $SUBSCRIPTION_ID --runtime "PYTHON:3.10" --os-type Linux