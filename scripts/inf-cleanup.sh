#!/bin/bash
set -e

# Colours for stdout
YELLOW='\e[1;33m'
RESET='\e[0m'

printInfo() {
    printf "$YELLOW\n%s$RESET\n" "$1"
}

figlet Infrastructure Cleanup

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${DIR}/load-env.sh

pushd "$DIR/../infrastructure" > /dev/null

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infrastructure"

# because of issues getting the VPN working on the destroy stage in the pipeline 
# we are skipping the VPN setup for destroy

# Remove them from terraform state as the destroy will still remove the storage accounts,
# at which point the file system no longer exists anyway!
# 'terraform state list' - gets you the list of the id's to delete
terraform state list | grep ".*.azurerm_storage_blob.appcode" | xargs --no-run-if-empty terraform state rm
terraform state list | grep ".*.azurerm_resource_group_template_deployment.workflow" | xargs --no-run-if-empty terraform state rm
terraform state list | grep ".*.azurerm_resource_group_template_deployment.cog_service" | xargs --no-run-if-empty terraform state rm
terraform state list | grep ".*.azurerm_key_vault_secret.secret*" | sed 's/"/\\"/g' | xargs --no-run-if-empty terraform state rm

set +e
terraform destroy -auto-approve
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then

    figlet Infrastructure DESTROY
    
    printInfo "Destruction failed, falling back to destroy resource group..."
    
    # Refresh state
    printInfo "Refreshing TF state:"
    terraform refresh
    
    # Remove everything from state except resource groups
    printInfo "Removing everything from state apart from the RG:"
    terraform state list | grep -v ".*azurerm_resource_group\\..*" | while read -r i; do terraform state rm $i; done
    
    # Delete resource groups
    printInfo "Destroying the RG:"
    terraform destroy -auto-approve
    
    EXIT_CODE=0
fi

# Delete the remote state
printInfo "Delete the workspace:"
terraform workspace select default
terraform workspace delete "${WORKSPACE}"

exit $EXIT_CODE
