# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Upgrade

# function to issue the import statement if the resource is not managed by Terraform
import_resource_if_needed() {
    local module_path=$1
    local resource_id=$2

    if [ ! -f "terraform.tfstate.d/$TF_VAR_environmentName/terraform.tfstate" ]; then
      # The RG is not managed by Terraform
      figlet "RG not managed by Terraform"
      echo "Deployment $TF_VAR_environmentName is not managed by Terraform. Importing $module_path"
      echo "Importing $module_path"
      terraform import "$module_path" "$resource_id"
    elif terraform state list | grep -q "$module_path"; then
      figlet "Managed by Terraform"
      # the module is already managed by terraform
      echo "Resource $module_path is already managed by Terraform"
    else  
      # the module is not managed by terraform
      figlet "Not managed by Terraform"
      echo "Importing $module_path"
      terraform import "$module_path" "$resource_id"

    fi
}


# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra" > /dev/null

echo "Current Folder: $(basename "$(pwd)")"
echo "state file: terraform.tfstate.d/${TF_VAR_environmentName}/terraform.tfstate"
# Initialise Terraform
terraform init -upgrade

echo
# Retrieve vars
for var in "${!TF_VAR_@}"; do
    echo "\$TF_VAR_${var#TF_VAR_} = ${!var}"
done

# Read randmom text suffix
file_path=".state/$TF_VAR_environmentName/random.txt"
if [ -f "$file_path" ]; then
    random_text=$(<"$file_path")
    random_text=$(echo "$random_text" | tr '[:upper:]' '[:lower:]')
    echo "rendom text suffix: $random_text"
else
    echo "Error: File '$TF_VAR_environmentName' not found."
fi


# Import the existing resources into the Terraform state
resourceId="/subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name"


# Resource Group
echo
echo -e "\e[1;32m Resource Group \e[0m"
import_resource_if_needed "azurerm_resource_group.rg" "$resourceId"
# providers="/providers/Microsoft.Resources/deployments/pid-$random_text"
# import_resource_if_needed "azurerm_resource_group_template_deployment.customer_attribution" "$resourceId$providers"

# Entra
echo
echo -e "\e[1;32m Entra \e[0m"


# Storage
echo
echo -e "\e[1;32m Storage \e[0m"
export TF_VAR_keyVaultId="infoasst-kv-$random_text"
export TF_VAR_name="infoasststore$random_text"

providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name"
import_resource_if_needed "module.storage.azurerm_storage_account.storage" "$resourceId$providers"
providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name/blobServices/default/containers/upload"
echo "zztop ***************: module.storage.azurerm_storage_container.container[1]" "$resourceId$providers"
import_resource_if_needed "module.storage.azurerm_storage_container.container[1]" "$resourceId$providers"
providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name/blobServices/default/containers/content"
# import_resource_if_needed "module.storage.azurerm_storage_container.container" "$resourceId$providers"
# providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name/blobServices/default/containers/function"
# import_resource_if_needed "module.storage.azurerm_storage_container.container" "$resourceId$providers"
# providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name/blobServices/default/containers/logs"
# import_resource_if_needed "module.storage.azurerm_storage_container.container" "$resourceId$providers"
# providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name/blobServices/default/containers/website"
# import_resource_if_needed "module.storage.azurerm_storage_container.container" "$resourceId$providers"




# providers="/providers/Microsoft.KeyVault/vaults/infoasst-kv-$random_text/secrets/BLOB-CONNECTION-STRING"
# import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_connection_string" "$resourceId$providers"

# providers="/providers/Microsoft.KeyVault/vaults/infoasst-kv-$random_text/secrets/AZURE-BLOB-STORAGE-KEY"
# import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_key" "$resourceId$providers"


# # Key vault
# echo
# echo -e "\e[1;32m Key vault \e[0m"
# export TF_VAR_keyVaultId="infoasst-kv-$random_text"
# export TF_VAR_name="infoasst-cosmos-$random_text"

# providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name"
# import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_account.cosmosdb_account" "$resourceId$providers"

# providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name/sqlDatabases/statusdb"
# import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_sql_database.log_database" "$resourceId$providers"

# providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name/sqlDatabases/tagdb"
# import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_sql_database.log_database" "$resourceId$providers"

# providers="/providers/Microsoft.KeyVault/vaults/infoasst-kv-$random_text/secrets/COSMOSDB-KEY"
# import_resource_if_needed "module.cosmosdb.azurerm_key_vault_secret.search_service_key" "$resourceId$providers"