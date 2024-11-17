# Copyright (c) DataReason.
### Code for On-Premises Deployment.

#!/bin/bash
set -e

CMD=az
NAME="Azure CLI"
echo -e "\e[34m»»» 📦 \e[32mInstalling \e[33m$NAME\e[0m ..."

# Install prerequisites
apt-get update
apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Add the Microsoft signing key and repository
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# Install the Azure CLI
apt-get update
apt-get install -y azure-cli

# Install CLI extensions
echo -e "\n\e[34m»»» 🔐 \e[32mAdding webapp authV2 extension"
az extension add --name authV2 --system

echo -e "\n\e[34m»»» 💾 \e[32mInstalled to: \e[33m$(which $CMD)"
echo -e "\e[34m»»» 💡 \e[32mVersion details: \e[39m$($CMD --version)"

#Explanation
#Azure CLI Installation: Installing the Azure CLI and adding the necessary repository and signing key.
#CLI Extensions: Adding the authV2 extension.