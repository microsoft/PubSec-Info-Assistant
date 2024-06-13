# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set +e

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# load env vars
source "${DIR}/load-env.sh"

# Clear the screen
clear
figlet Manual Infrastructure DESTROY

# Function to change text color to yellow
set_yellow_text() {
    tput setaf 3  # Set text color to yellow
}

# Function to reset text color
reset_text_color() {
    tput sgr0  # Reset text color
}

# Set text color to yellow
set_yellow_text
echo "This script will destroy all servcies deployed as part of a tergetted resource group."
echo "Pease ensure you have authenticated an have the necessary permissions to delete the resources."
echo ""
echo "Please enter the name of the resource group you wish to destroy:"
reset_text_color
read rg_name
echo ""
#Prompt the user for oa_ai resource group
set_yellow_text
echo ""
echo "Please enter the name of the open ai resource group your resource group is connected to:"
reset_text_color
read oa_ai_rg_name
echo ""

# Prompt the user for confirmation
set_yellow_text
echo "Do you wish to continue and destroy '$rg_name'? Type 'yes' to proceed."
reset_text_color
read response
set_yellow_text
# Check the user's input
if [ "$response" == "yes" ]; then
    echo "Proceeding..."
    # Place your code here that should run after confirmation
else
    echo "Exiting..."
    exit 0
fi
echo ""

# Final approval
random_number=$((10 + RANDOM % 90))
echo "FINAL CONFIRMATION:"
echo "To confirm you wish to destroy the resources in the resource group '$rg_name', please enter $random_number:"
echo "Enter the number to proceed:"
reset_text_color
read user_input
echo ""

# Check if the entered number matches the generated number
set_yellow_text
if [ "$user_input" -eq "$random_number" ]; then
    echo "Ok, prooceeding..."
else
    echo "Incorrect number entered. Exiting..."
    exit 0
fi
reset_text_color


#*************************
# Delete services

# Get the first storage account name from the resource group and trim to the last 5 characters
storage_account_name=$(az resource list --resource-group $rg_name --resource-type \
    "Microsoft.Storage/storageAccounts" --query "[0].name" -o tsv)
random_text=${storage_account_name: -5}
echo "Resource group: $rg_name"
echo "Random text: $random_text"

#delete ao_ai connection
echo "Deleting open ai connection..."
appid=$(az ad sp list --all --query "[?displayName=='infoasst-web-$random_text'].appId" -o tsv)
echo "Deleting role assignment for app id: $appid"
role_assignment_id=$(az role assignment list --resource-group $oa_ai_rg_name --query "[?principalName=='$appid'].id" -o tsv)
echo "Role assignment id: $role_assignment_id"
az role assignment delete --ids $role_assignment_id
echo "Role assignment deleted."

# Delete RG
az group delete \
    --resource-group $rg_name \
    --yes \
    --no-wait 
echo "Resource group is being deleted."
echo "Continuing..."



# Delete app regitsrations
app_name="infoasst_mgmt_access_$random_text"
app_id=$(az ad app list --display-name $app_name --query "[].appId" -o tsv)
if [ -z "$app_id" ]; then
    echo "No application registration found with the given name."
    exit 1
else
    # Step 2: Delete the application
    echo "Deleting application $app_name."
    az ad app delete --id $app_id
fi

app_name="infoasst_web_access_$random_text"
app_id=$(az ad app list --display-name $app_name --query "[].appId" -o tsv)
if [ -z "$app_id" ]; then
    echo "No application registration found with the given name."
    exit 1
else
    # Step 2: Delete the application
    echo "Deleting application $app_name."
    az ad app delete --id $app_id
fi

# Delete the terraform state
echo "Deleting TF state files"
rg_suffix=${rg_name#infoasst-}
rm -r $(pwd)/infra/terraform.tfstate.d/$rg_suffix


echo ""
echo "All services have been successfully deleted."
