# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
#
# This script repoints a deployment to a prior existing depolyment
# to allow a new deployment to consumes assest from cosmsos db, storage account, 
# and to use the search index. The intent is to allow the system to 
# continue to consume prior processed content and for new content to 
# be loaded to the old RG storage account and cosmos db.
# Where possible use a new deployment fully and cleanly



figlet Repointing
echo "-----------------------------------"
echo "This script repoints a deployment to a prior existing depolyment"
echo


# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
source "${DIR}/prepare-tf-variables.sh"
pushd "$DIR/../infra" > /dev/null
echo "Current Folder: $(basename "$(pwd)")"
echo "state file: terraform.tfstate.d/${TF_VAR_environmentName}/terraform.tfstate"

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra/"
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
    echo "random text suffix: $random_text"
else
    # If the random text suffix is not found in random.txt, prompt the user for input
    echo "random text not read"
    echo -e "\033[1;33mPlease enter the random text suffix used in the names of your newly deployed azure services:\033[0m"
    read user_input
    echo
    # Assign the input to a variable
    random_text=$user_input
fi

# # Get the directory that this script is in
FILE_PATH="$DIR/upgrade_repoint.config.json"
old_resource_group=$(jq -r '.old_env.old_resource_group' $FILE_PATH)
old_random_text=$(jq -r '.old_env.old_random_text' $FILE_PATH)
new_resource_group="infoasst-$TF_VAR_environmentName"
new_random_text=$random_text
subscription=$TF_VAR_subscriptionId


#############################################################
figlet "Role Access"
# Grant role access to resources in old resource group"

# Retrieve principal ids
sp_infoasst_mgmt_access=$(az ad sp list --filter "displayName eq 'infoasst_mgmt_access_$new_random_text'" --query "[].appId" --output tsv)
sp_infoasst_func=$(az ad sp list --filter "displayName eq 'infoasst-func-$new_random_text'" --query "[].id" --output tsv)
sp_infoasst_enrichmentweb=$(az ad sp list --filter "displayName eq 'infoasst-enrichmentweb-$new_random_text'" --query "[].id" --output tsv)
sp_infoasst_web=$(az ad sp list --filter "displayName eq 'infoasst-web-$new_random_text'" --query "[].id" --output tsv)
echo "sp_infoasst_mgmt_access: $sp_infoasst_mgmt_access"
echo "sp_infoasst-func: $sp_infoasst_func"
echo "sp_infoasst-enrichmentweb: $sp_infoasst_enrichmentweb"
echo "sp_infoasst-web-: $sp_infoasst_web"

# assign roles & access policies
az keyvault set-policy --name infoasst-kv-$old_random_text --object-id $sp_infoasst_func --secret-permissions get list 
az keyvault set-policy --name infoasst-kv-$old_random_text --object-id $sp_infoasst_enrichmentweb --secret-permissions get list 
az keyvault set-policy --name infoasst-kv-$old_random_text --object-id $sp_infoasst_web --secret-permissions get list 

az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Search Index Data Contributor" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Search Index Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"

az role assignment create --assignee "$sp_infoasst_func" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"

az role assignment create --assignee "$sp_infoasst_web" --role "Search Index Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_web" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"


#############################################################
figlet "Functions Configuration"
app_name="infoasst-func-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_CONNECTION_STRING"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/BLOB-CONNECTION-STRING)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_STORAGE_ACCOUNT_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null


#############################################################
figlet "Web App Configuration"
app_name="infoasst-web-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE"
setting_value="infoasst-search-$old_random_text"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null


#############################################################
figlet "Enrichment App Configuration"
app_name="infoasst-enrichmentweb-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE"
setting_value="infoasst-search-$old_random_text"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_STORAGE_CONNECTION_STRING"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/BLOB-CONNECTION-STRING)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_CONNECTION_STRING"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/BLOB-CONNECTION-STRING)"
az functionapp config appsettings set --name "$app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null


#############################################################
figlet "Delete old services"
# Delete unrequired services from the old resource group"

resource_group=$old_resource_group
function_app="infoasst-func-$old_random_text"
web_app="infoasst-web-$old_random_text"
enrichment_app="infoasst-enrichmentasp-$old_random_text"

# Function to delete a service and handle non-existence
delete_service() {
    service_type=$1
    service_name=$2
    echo "Checking if $service_type $service_name exists..."
    if az $service_type show --name $service_name --resource-group $resource_group > /dev/null 2>&1; then
        echo "$service_type $service_name exists. Attempting to delete..."
        if az $service_type delete --name $service_name --resource-group $resource_group --yes; then
            echo "$service_type $service_name deleted successfully."
            deleted_services+=("$service_type $service_name")
        else
            echo "Failed to delete $service_type $service_name."
            failed_services+=("$service_type $service_name")
        fi
    else
        echo "$service_type $service_name does not exist."
        non_existing_services+=("$service_type $service_name")
    fi
}

# ANSI yellow color code
yellow='\033[1;33m'
no_color='\033[0m'  # No color (reset color)

# Confirmation prompt in yellow
echo -e "${yellow}Do you wish to delete the function app, web app, and enrichment app? (y/n)${no_color}"
read -p "" answer

case $answer in
    [Yy]* )
        deleted_services=()
        failed_services=()
        delete_service "functionapp" $function_app
        delete_service "webapp" $web_app
        delete_service "webapp" $enrichment_app

        # Final report
        echo "Deletion process complete."
        if [ ${#deleted_services[@]} -ne 0 ]; then
            echo "The following services were deleted successfully:"
            printf " - %s\n" "${deleted_services[@]}"
        fi

        if [ ${#failed_services[@]} -ne 0 ]; then
            echo "The following services could not be deleted or did not exist:"
            printf " - %s\n" "${failed_services[@]}"
        fi
        ;;
    * )
        echo "Deletion cancelled."
        ;;
esac

