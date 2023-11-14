# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

echo -n "Please enter your WORKSPACE: "
read workspace
export WORKSPACE=$workspace

echo -n "Please enter the Azure Storage Account for CI/CD State management: "
read storage_account
export AZURE_STORAGE_ACCOUNT=$storage_account

echo -n "Please enter the Azure Storage Account Key for CI/CD State management: "
read storage_account_key
export AZURE_STORAGE_ACCOUNT_KEY=$storage_account_key

echo -n "Would you like users to have to be explicitly assigned to the app? (y/n): "
read require_website_security_membership
export REQUIRE_WEBSITE_SECURITY_MEMBERSHIP=$require_website_security_membership

figlet Create AD Objects

# get or create the random.txt from local file system
if [ -f "../infra/.state/${WORKSPACE}/random.txt" ]; then
  #echo "random.txt exists"
  randomString=$(cat ../infra/.state/${WORKSPACE}/random.txt)
else  
  #echo "random.txt does not exist"
  randomString=$(mktemp --dry-run XXXXX)
  mkdir -p ../infra/.state/${WORKSPACE}
  echo $randomString >> ../infra/.state/${WORKSPACE}/random.txt
fi

export RANDOM_STRING="${randomString,,}"

if [ -n "${IS_USGOV_DEPLOYMENT}" ] && $IS_USGOV_DEPLOYMENT; then
  az cloud set --name AzureUSGovernment 
  auth_callback_url="https://infoasst-web-$RANDOM_STRING.azurewebsites.us/.auth/login/aad/callback"
else
  auth_callback_url="https://infoasst-web-$RANDOM_STRING.azurewebsites.net/.auth/login/aad/callback"
fi

# add the random.txt to the state container
#echo "az storage blob exists --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --output tsv --query exists"
exists=$(az storage blob exists --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --output tsv --query exists)
#echo "exists: $exists"
if [ $exists == "true" ]; then
  #echo "az storage blob download --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --query content --output tsv"
  randomString=$(az storage blob download --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --query content --output tsv)
  rm ../infra/.state/${WORKSPACE}/random.txt
  echo $randomString >> ../infra/.state/${WORKSPACE}/random.txt
else
  #echo "az storage blob upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --file .state/${WORKSPACE}/random.txt"
  upload=$(az storage blob upload --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_ACCOUNT_KEY --container-name state --name ${WORKSPACE}.random.txt --file ../infra/.state/${WORKSPACE}/random.txt)
fi


signedInUserId=$(az ad signed-in-user show --query id --output tsv)
#if not in automation, create the app registration and service principal values
#set up azure ad app registration since there is no bicep support for this yet
aadWebAppId=$(az ad app list --display-name infoasst_web_access_$RANDOM_STRING --output tsv --query [].appId)
if [ -z $aadWebAppId ]; then
    echo "Creating new AD App Registration: infoasst_web_access_$RANDOM_STRING"   
    aadWebAppId=$(az ad app create --display-name infoasst_web_access_$RANDOM_STRING --sign-in-audience AzureADMyOrg --identifier-uris "api://infoasst-$RANDOM_STRING" --web-redirect-uris $auth_callback_url --enable-access-token-issuance true --enable-id-token-issuance true --output tsv --query "[].appId")
    aadWebAppId=$(az ad app list --display-name infoasst_web_access_$RANDOM_STRING --output tsv --query [].appId)
fi

aadWebSPId=$(az ad sp list --display-name infoasst_web_access_$RANDOM_STRING --output tsv --query "[].id")
if [ -z $aadWebSPId ]; then
    echo "Creating new AD Service Principal: infoasst_web_access_$RANDOM_STRING"
    aadWebSPId=$(az ad sp create --id $aadWebAppId --output tsv --query "[].id")
    aadWebSPId=$(az ad sp list --display-name infoasst_web_access_$RANDOM_STRING --output tsv --query "[].id")
fi

if [ $REQUIRE_WEBSITE_SECURITY_MEMBERSHIP ]; then
  # if the REQUIRE_WEBSITE_SECURITY_MEMBERSHIP is set to true, then we need to update the app registration to require assignment
  az ad sp update --id $aadWebSPId --set "appRoleAssignmentRequired=true"
else
  # otherwise the default is to allow all users in the tenant to access the app
  az ad sp update --id $aadWebSPId --set "appRoleAssignmentRequired=false"
fi

aadMgmtAppId=$(az ad app list --display-name infoasst_mgmt_access_$RANDOM_STRING --output tsv --query [].appId)
if [ -z $aadMgmtAppId ]
  then
    aadMgmtAppId=$(az ad app create --display-name infoasst_mgmt_access_$RANDOM_STRING --sign-in-audience AzureADMyOrg --output tsv --query "[].appId")
    aadMgmtAppId=$(az ad app list --display-name infoasst_mgmt_access_$RANDOM_STRING --output tsv --query [].appId)
    aadMgmtAppSecret=$(az ad app credential reset --id $aadMgmtAppId --display-name infoasst-mgmt --output tsv --query password)
  fi

aadMgmtSPId=$(az ad sp list --display-name infoasst_mgmt_access_$RANDOM_STRING --output tsv --query "[].id")
if [ -z $aadMgmtSPId ]; then
    aadMgmtSPId=$(az ad sp create --id $aadMgmtAppId --output tsv --query "[].id")
    aadMgmtSPId=$(az ad sp list --display-name infoasst_mgmt_access_$RANDOM_STRING --output tsv --query "[].id")
fi

#output the values to the console
echo -e "\n\n"
echo "Remember to use these values in your pipeline configuration"
echo -e "\n" 
echo "WORKSPACE: " $WORKSPACE
echo "Website App Registration: " $aadWebAppId
echo "Management App Registration: " $aadMgmtAppId
echo "Management App Secret: " $aadMgmtAppSecret
echo "Management Service Principal: " $aadMgmtSPId