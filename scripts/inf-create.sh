# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Infrastructure

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

if [ -n "${IN_AUTOMATION}" ]; then
  export TF_VAR_isInAutomation=true
  
  if [[ $WORKSPACE = tmp* ]]; then
    # if in automation for PR builds, get the app registration and service principal values from the already logged in SP
    aadWebAppId=$ARM_CLIENT_ID
    aadMgmtAppId=$ARM_CLIENT_ID
    aadWebSPId=$ARM_SERVICE_PRINCIPAL_ID
    aadMgmtAppSecret=$ARM_CLIENT_SECRET
    aadMgmtSPId=$ARM_SERVICE_PRINCIPAL_ID
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

  fi

  # prepare the AD object variables for Terraform
  export TF_VAR_aadWebClientId=$aadWebAppId
  export TF_VAR_aadMgmtClientId=$aadMgmtAppId
  export TF_VAR_aadMgmtServicePrincipalId=$aadMgmtSPId
  export TF_VAR_aadMgmtClientSecret=$aadMgmtAppSecret
fi

if [ -n "${IN_AUTOMATION}" ]
then

    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ $AZURE_ENVIRONMENT == "AzureUSGovernment" ]]; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

# Check for capacity for diagnostic settings
if [[ $SECURE_MODE == "true" ]]; then
    diag_settings_count=$(az monitor diagnostic-settings subscription list --query "length(value)" --output tsv)
    max_diag_settings=5
    remaining_capacity=$((max_diag_settings - diag_settings_count))

    echo -e "Current diagnostic settings count: \e[32m$diag_settings_count\e[0m"
    echo -e "Maximum allowed diagnostic settings: \e[32m$max_diag_settings\e[0m"
    echo -e "Remaining capacity for diagnostic settings: \e[32m$remaining_capacity\e[0m"

    if [ "$diag_settings_count" -ge "$max_diag_settings" ]; then
        echo -e "\e[31mError: Maximum diagnostic settings capacity reached ($max_diag_settings).\n\e[0m"
        echo -e "You currently have no capacity left for new diagnostic settings.\n\e[0m"
        
        # Display existing diagnostic settings
        echo -e "\e[1;34mHere are the current diagnostic settings:\e[0m"
        az monitor diagnostic-settings subscription list --query "value[].{name: name, resourceId: targetResourceId}" --output table
        echo -e "\n"
        echo -e "Please delete an existing diagnostic setting before proceeding.\n"

         # Provide the command to delete a diagnostic setting
        echo -e "\e[1;34mTo delete a diagnostic setting, use this command:\e[0m"
        echo -e "az monitor diagnostic-settings subscription delete --name <diagnostic setting name>\n"

        # Exit the script to prevent further execution
        exit 1
    else
        echo -e "\e[33mYou have $remaining_capacity diagnostic settings capacity left.\n\e[0m"
    fi
else
    echo -e "\e[32mSECURE_MODE is set to false, skipping diagnostic settings capacity check.\n\e[0m"
fi

# Check for existing DDOS Protection Plan and use it if available
if [[ "$SECURE_MODE" == "true" ]]; then
    if [[ -z "$DDOS_PLAN_ID" ]]; then
        # No DDOS_PLAN_ID provided in the environment, look up Azure for an existing DDOS plan
        DDOS_PLAN_ID=$(az network ddos-protection list --query "[?contains(name, 'ddos')].id | [0]" --output tsv)
        
        if [[ -z "$DDOS_PLAN_ID" ]]; then
            echo -e "\e[31mNo existing DDOS protection plan found. Terraform will create a new one.\n\e[0m"
        else
            echo "Found existing DDOS Protection Plan: $DDOS_PLAN_ID"
            read -p "Do you want to use this existing DDOS Protection Plan (y/n)? " use_existing
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                echo -e "Using existing DDOS Protection Plan: $DDOS_PLAN_ID\n"
                export TF_VAR_ddos_plan_id="$DDOS_PLAN_ID"

                echo -e "-------------------------------------\n"
                echo "DDOS_PLAN_ID is set to: $DDOS_PLAN_ID"
                echo -e "-------------------------------------\n"

            else
                export TF_VAR_ddos_plan_id=""  # Clear the variable to indicate that a new plan should be created
                echo "A new DDOS Protection Plan will be created by Terraform."
            fi
        fi
    else
        echo -e "Using provided DDOS Protection Plan ID from environment: $DDOS_PLAN_ID\n"
        export TF_VAR_ddos_plan_id="$DDOS_PLAN_ID"
    fi
fi

# Create our application configuration file before starting infrastructure
${DIR}/configuration-create.sh

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra/"

${DIR}/terraform-plan-apply.sh -d "$DIR/../infra" -p "infoasst" -o "$DIR/../inf_output.json"