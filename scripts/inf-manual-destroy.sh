# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

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

# Display the notice
echo "IMPORTANT NOTICE:"
echo "Please read the following terms carefully. You must accept the terms to proceed."
echo
echo "This script will import the existing resources into the Terraform state."
echo "You may then run a MAKE DEPLOY on this environment to deploy the latest version"
echo "of the accelerator while maintaining your existing resources and processed data."
echo
echo "If you have modified the infrastructure base this process will fail."
echo "The simplest approach to deploy the latest version would be to perform"
echo "a new deployment on a new resource group and reprocess your data"

# Reset text color for input promptccc
reset_text_color
echo
echo "Do you accept these terms? (yes/no)"

# Wait for the user's input
while true; do
    read -rp "Type 'yes' to accept: " answer
    case $answer in
        [Yy]* ) break;;
        [Nn]* ) echo "You did not accept the terms. Exiting."; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Continue with the script after acceptance
echo "You have accepted the terms. Proceeding with the script..."
# Your script's logic goes here





















if [ -n "${IN_AUTOMATION}" ]
then
    echo "Delete the resource group $RG_NAME, but don't wait (fire and forget)"

    if [ -n "${AZURE_ENVIRONMENT}" ] && [[ $AZURE_ENVIRONMENT == "AzureUSGovernment" ]]; then
        az cloud set --name AzureUSGovernment 
    fi

    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    az account set -s "$ARM_SUBSCRIPTION_ID"
    az group delete \
        --resource-group $TF_VAR_resource_group_name \
        --yes \
        --no-wait

    echo "Resource group will be deleted."
else
    echo "ERROR: inf-destroy.sh does not run outside of build automation"
    echo "Use the following command to do this manually:"
    echo
    echo az group delete --resource-group $TF_VAR_resource_group_name --yes --no-wait
    echo
fi
