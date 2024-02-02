#!/bin/bash
set -e

figlet Infrastructure

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra-tf" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

################################################################
echo "Setting up random.txt file for your environment"

#set up variables for the bicep deployment
#get or create the random.txt from local file system
if [ -f ".state/${WORKSPACE}/random.txt" ]; then
  randomString=$(cat .state/${WORKSPACE}/random.txt)
else  
  randomString=$(mktemp --dry-run XXXXX)
  mkdir -p .state/${WORKSPACE}
  echo $randomString >> .state/${WORKSPACE}/random.txt
fi

WEB_APP_ENDPOINT_SUFFIX="azurewebsites.net"

if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
  WEB_APP_ENDPOINT_SUFFIX="azurewebsites.us"
fi

if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT && ! $USE_EXISTING_AOAI; then
  echo "AOAI doesn't exist in US Gov regions.  Please create AOAI seperately and update the USE_EXISTING_AOAI in the env file. "
  exit 1  
fi

if [ -n "${IN_AUTOMATION}" ]; then
  #if in automation, add the random.txt to the state container
  #echo "az storage blob exists --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --output tsv --query exists"
  exists=$(az storage blob exists --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --output tsv --query exists)
  #echo "exists: $exists"
  if [ $exists == "true" ]; then
    #echo "az storage blob download --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --query content --output tsv"
    randomString=$(az storage blob download --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --query content --output tsv)
    rm .state/${WORKSPACE}/random.txt
    echo $randomString >> .state/${WORKSPACE}/random.txt
  else
    #echo "az storage blob upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --file .state/${WORKSPACE}/random.txt"
    upload=$(az storage blob upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --file .state/${WORKSPACE}/random.txt)
  fi
fi
randomString="${randomString,,}"
export RANDOM_STRING=$randomString

echo -e "\n"
echo "Setting up Azure AD App Registration and Service Principal for your environment"

if [ -n "${IN_AUTOMATION}" ]; then
  signedInUserId=$ARM_CLIENT_ID
  workspace=$WORKSPACE
  if [[ $workspace = tmp* ]]; then
    # if in automation for PR builds, get the app registration and service principal values from the already logged in SP
    aadWebAppId=$ARM_CLIENT_ID
    aadMgmtAppId=$ARM_CLIENT_ID
    aadWebSPId=$ARM_SERVICE_PRINCIPAL_ID
    aadMgmtAppSecret=$ARM_CLIENT_SECRET
    aadMgmtSPId=$ARM_SERVICE_PRINCIPAL_ID
    kvAccessObjectId=$aadWebSPId
  else
    # if in automation for non-PR builds, get the app registration and service principal values from the manually created AD objects
    aadWebAppId=$AD_WEBAPP_CLIENT_ID
    if [ -z $aadWebAppId ]; then
      echo "An Azure AD App Registration and Service Principal must be manually created for the targeted workspace."
      echo "Please create the Azure AD objects using the script at /scripts/create-ad-objs-for-deployment.sh and set the AD_WEBAPP_CLIENT_ID pipeline variable in Azure DevOps."
      exit 1  
    fi
    aadMgmtAppId=$AD_MGMTAPP_CLIENT_ID
    aadMgmtAppSecret=$AD_MGMTAPP_CLIENT_SECRET
    aadMgmtSPId=$AD_MGMT_SERVICE_PRINCIPAL_ID
    kvAccessObjectId=$aadWebSPId

  fi

  export SINGED_IN_USER_PRINCIPAL=$signedInUserId
  export AZURE_AD_WEB_APP_CLIENT_ID=$aadWebAppId
  export AZURE_AD_MGMT_APP_CLIENT_ID=$aadMgmtAppId
  export AZURE_AD_MGMT_SP_ID=$aadMgmtSPId
  export AZURE_AD_MGMT_APP_SECRET=$aadMgmtAppSecret
  export AZURE_KV_ACCESS_OBJ_ID=$kvAccessObjectId
  export TF_VAR_kvAccessObjectId=$kvAccessObjectId
  export TF_VAR_principalId=$signedInUserId
  export TF_VAR_aadMgmtClientId=$aadMgmtAppId
  export TF_VAR_aadMgmtClientSecret=$aadMgmtAppSecret
  export TF_VAR_aadMgmtServicePrincipalId=$aadMgmtSPId
  export TF_VAR_aadWebClientId=$aadWebAppId
fi

export TF_VAR_randomString=$RANDOM_STRING
export TF_VAR_webAppSuffix=$WEB_APP_ENDPOINT_SUFFIX



if [ -n "${IN_AUTOMATION}" ]; then 
  export IS_IN_AUTOMATION=true
  export TF_VAR_isInAutomation=true
else 
  export IS_IN_AUTOMATION=false
  export TF_VAR_isInAutomation=false
fi

############################################################


# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra-tf/"

${DIR}/terraform-plan-apply.sh -d "$DIR/../infra-tf" -p "infoasst" -o "$DIR/../inf_output.json"