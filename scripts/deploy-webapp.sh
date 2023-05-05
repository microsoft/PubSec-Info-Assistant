#!/bin/bash
set -e

figlet Deploy Webapp

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
source "${DIR}/environments/infrastructure.env"
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"

end=`date -u -d "3 years" '+%Y-%m-%dT%H:%MZ'`

cd $BINARIES_OUTPUT_PATH
file=$(az storage blob upload --account-name $AZURE_BLOB_STORAGE_ACCOUNT --account-key $AZURE_BLOB_STORAGE_KEY --container-name website --name webapp.zip --file webapp.zip --overwrite)
sas=$(az storage blob generate-sas --account-name $AZURE_BLOB_STORAGE_ACCOUNT --account-key $AZURE_BLOB_STORAGE_KEY --container-name website --name webapp.zip --permissions r --expiry $end --output tsv)
az webapp deploy --name $AZURE_WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME --type zip --src-url "https://$AZURE_BLOB_STORAGE_ACCOUNT.blob.core.windows.net/website/webapp.zip?$sas" --timeout 300000