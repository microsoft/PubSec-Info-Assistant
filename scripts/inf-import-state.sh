# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Import Terraform State

# escape special chars in a string
escape_string() {
    echo "$1" | sed 's/[][]/\\&/g'
}

# function to issue the import statement if the resource is not managed by Terraform
import_resource_if_needed() {
    local module_path=$1
    local resource_id=$2

    # endcode the $module_path
    module_path_escaped=$(escape_string "$module_path") 

    if [ ! -f "terraform.tfstate.d/$TF_VAR_environmentName/terraform.tfstate" ]; then
      # The RG is not managed by Terraform
      echo -e "\e[34mDeployment $TF_VAR_environmentName is not managed by Terraform. Importing $module_path\e[0m"
      terraform import "$module_path" "$resource_id"
    elif terraform state list | grep -q $module_path_escaped; then
      echo -e "\e[34mResource $module_path is already managed by Terraform\e[0m"
    else 
      # the module is not managed by terraform
      echo -e "\e[34mResource $module_path is not managed by Terraform. Importing $module_path\e[0m"
      terraform import "$module_path" "$resource_id"
    fi

}


get_secret() {
    local secret_name=$1
    keyVaultId="infoasst-kv-$random_text"
    local secret_id=$(az keyvault secret show --name $secret_name --vault-name $keyVaultId --query id -o tsv)
    echo $secret_id
}


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
    echo
    echo -e "\033[1;33mPlease enter the random text suffix used in the names of your azure services:\033[0m"
    read user_input
    echo
    # Assign the input to a variable
    random_text=$user_input
fi


# ***********************************************************
# Import the existing resources into the Terraform state
# ***********************************************************

# Main
echo
figlet "Main"
resourceId="/subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name"
import_resource_if_needed "azurerm_resource_group.rg" "$resourceId"
providers="/providers/Microsoft.Resources/deployments/pid-"
import_resource_if_needed "azurerm_resource_group_template_deployment.customer_attribution[0]" "$resourceId$providers"


# Entra 
echo
figlet "Entra"
webAccessApp_name="infoasst_web_access_$random_text"
# webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].application_id" --all | jq -r '.[0]')
webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
import_resource_if_needed "module.entraObjects.azuread_application.aad_web_app[0]" "/applications/$webAccessApp_objectId"
appName="infoasst-web-$random_text"
service_principal_id=$(az ad sp list --display-name "$appName" --query "[].id" | jq -r '.[0]')
import_resource_if_needed "module.entraObjects.azuread_service_principal.aad_web_sp[0]" $service_principal_id
webAccessApp_name="infoasst_mgmt_access_$random_text"
webAccessApp_id=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
import_resource_if_needed "module.entraObjects.azuread_application.aad_mgmt_app[0]" "/applications/$webAccessApp_id"


# OpenAI Services
echo
figlet "OpenAI Services"
name="infoasst-aoai-$random_text"
# only import if the service exists in the RG
serviceExists=$(az resource list --resource-group "$TF_VAR_resource_group_name" --query "[?name=='$name'] | [0].name" --output tsv)
if [[ $serviceExists == $name ]]; then
    providers="/providers/Microsoft.CognitiveServices/accounts/$name"
    import_resource_if_needed "module.openaiServices.azurerm_cognitive_account.account" "$resourceId$providers"

    # providers="/providers/Microsoft.CognitiveServices/accounts/$account1/deployments/$deployment1"
    # import_resource_if_needed "module.openaiServices.azurerm_cognitive_deployment.deployment" "$resourceId$providers"
    # /providers/Microsoft.CognitiveServices/accounts/account1/deployments/deployment1

    # $TF_VAR_chatGptDeploymentName 
    # $TF_VAR_azureOpenAIEmbeddingDeploymentNam

else
    echo -e "\e[34mService $name not found in resource group $TF_VAR_resource_group_name.\e[0m"
fi


# Monitor
echo
figlet "Monitor"
name="infoasst-lw--$random_text"
workbook_name=$(az resource list --resource-group infoasst-geearl-837 --resource-type "Microsoft.Insights/workbooks" --query "[?type=='Microsoft.Insights/workbooks'].name | [0]" -o tsv)
providers="/providers/Microsoft.Insights/workbooks/$workbook_name"
import_resource_if_needed "module.azMonitor.azurerm_application_insights_workbook.example" "$resourceId$providers"


# Video Indexer
echo
figlet "Video Indexer"
name="infoasststoremedia$random_text"
providers="/providers/Microsoft.Storage/storageAccounts/$name"
import_resource_if_needed "module.video_indexer.azurerm_storage_account.media_storage" "$resourceId$providers"
name="infoasst-ua-ident-$random_text"
providers="/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$name"
import_resource_if_needed "module.video_indexer.azurerm_user_assigned_identity.vi" "$resourceId$providers"

# Retrive the principal id used to identify which roles are matched to this module
# roles are assigned elswhere in the code, and have an assigned principal id
# in the user roles module, the porinipal id of the user doing the deployment is used
# to work around this identify the principals used in the other modules and
# and filter role assignments from here that do not match these id's
principalId1=$(az ad sp list --display-name infoasst-web-$random_text --query "[].id" --output tsv)
# Loop through each role assignment in the output and import
echo "$output" | jq -c '.[]' | while read -r line; do
    # Extract 'roleDefinitionName' and 'id' from the output
    roleDefinitionName=$(echo $line | jq -r '.roleDefinitionName' | tr -d ' ')
    roleId=$(echo $line | jq -r '.id')
    rolePrincipalId=$(echo $line | jq -r '.principalId')
    # Check if this principal id is in the list of excluded principals
    # if not, then import this item
    if [ "$rolePrincipalId" = "$principalId1" ]; then
        # Check if the roleDefinitionName is in the list of selected roles
        # Use pattern matching after removing spaces from roleDefinitionName
        if [[ " ${selected_roles[*]} " =~ " ${roleDefinitionName// /} " ]]; then
            import_resource_if_needed "module.video_indexer[\"$roleDefinitionName\"].azurerm_role_assignment.role" "$roleId"
        fi
    fi  
done

name="infoasst-ua-ident-$random_text"
providers="/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$name"
import_resource_if_needed "module.video_indexer.azurerm_resource_group_template_deployment.vi" "$resourceId$providers"


providers/Microsoft.Resources/deployments/avi-1b570f1f3cf66a1f0e9fce566ae1bc40",




















# Form Recognizer
echo
figlet "Form Recognizer"
name="infoasst-fr-$random_text"
providers="/providers/Microsoft.CognitiveServices/accounts/$name"
import_resource_if_needed "module.formrecognizer.azurerm_cognitive_account.formRecognizerAccount" "$resourceId$providers"
secret_id=$(get_secret "AZURE-FORM-RECOGNIZER-KEY")
import_resource_if_needed "module.cognitiveServices.azurerm_key_vault_secret.search_service_key" "$secret_id"


# Cognitive Services 
echo
figlet "Cognitive Services"
name="infoasst-enrichment-cog-$random_text"
providers="/providers/Microsoft.CognitiveServices/accounts/$name"
import_resource_if_needed "module.cognitiveServices.azurerm_cognitive_account.cognitiveService" "$resourceId$providers"
secret_id=$(get_secret "ENRICHMENT-KEY")
import_resource_if_needed "module.cognitiveServices.azurerm_key_vault_secret.search_service_key" "$secret_id"


# Logging
echo
figlet "Logging"
name="infoasst-la-$random_text"
providers="/providers/Microsoft.OperationalInsights/workspaces/$name"
import_resource_if_needed "module.logging.azurerm_log_analytics_workspace.logAnalytics" "$resourceId$providers"
name="infoasst-ai-$random_text"
providers="/providers/Microsoft.Insights/components/$name"
import_resource_if_needed "module.logging.azurerm_application_insights.applicationInsights" "$resourceId$providers"




# User Roles
echo
figlet "User Roles"
# Retrieve each role assignment from azure
output=$(az role assignment list \
  --subscription $TF_VAR_subscriptionId \
  --resource-group $TF_VAR_resource_group_name \
  --query "[].{roleDefinitionName: roleDefinitionName, id: id, principalId: principalId}" \
  --output json)

# list of roleDefinitionNames to associate with this module
selected_roles=("CognitiveServicesOpenAIUser" "StorageBlobDataReader" "StorageBlobDataContributor" "SearchIndexDataReader" "SearchIndexDataContributor")

# Retrive the principal id used to identify which roles are matched to this module
# roles are assigned elswhere in the code, and have an assigned principal id
# in the user roles module, the porinipal id of the user doing teh deployment is used
# to work around this identify the principals used in the other modules and
# and filter role assignments from here that do not match these id's
principalId1=$(az ad sp list --display-name infoasst-web-$random_text --query "[].id" --output tsv)

# Loop through each role assignment in the output and import
echo "$output" | jq -c '.[]' | while read -r line; do
    # Extract 'roleDefinitionName' and 'id' from the output
    roleDefinitionName=$(echo $line | jq -r '.roleDefinitionName' | tr -d ' ')
    roleId=$(echo $line | jq -r '.id')
    rolePrincipalId=$(echo $line | jq -r '.principalId')
    # Check if this principal id is in the list of excluded principals
    # if not, then import this item
    if [ "$rolePrincipalId" != "$principalId1" ]; then
        # Check if the roleDefinitionName is in the list of selected roles
        # Use pattern matching after removing spaces from roleDefinitionName
        if [[ " ${selected_roles[*]} " =~ " ${roleDefinitionName// /} " ]]; then
            import_resource_if_needed "module.userRoles[\"$roleDefinitionName\"].azurerm_role_assignment.role" "$roleId"
        fi
    fi  
done


# Key Vault
echo
figlet "Key Vault"
keyVaultId="infoasst-kv-$random_text"
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId"
import_resource_if_needed "module.kvModule.azurerm_key_vault.kv" "$resourceId$providers"
secret_id=$(get_secret "AZURE-CLIENT-SECRET")
import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_connection_string" "$secret_id"


# Functions
echo
figlet "Functions"
appServicePlanName="infoasst-func-asp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
import_resource_if_needed "module.functions.azurerm_service_plan.funcServicePlan" "$resourceId$providers"
providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
import_resource_if_needed "module.functions.azurerm_monitor_autoscale_setting.scaleout" "$resourceId$providers"
appName="infoasst-func-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
import_resource_if_needed "module.functions.azurerm_linux_function_app.function_app" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
import_resource_if_needed "module.functions.azurerm_key_vault_access_policy.policy" "$resourceId$providers"


# Web App
echo
figlet "Web App"
appServicePlanName="infoasst-asp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
import_resource_if_needed "module.backend.azurerm_service_plan.appServicePlan" "$resourceId$providers"
providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
import_resource_if_needed "module.backend.azurerm_monitor_autoscale_setting.scaleout" "$resourceId$providers"
appName="infoasst-web-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
import_resource_if_needed "module.backend.azurerm_linux_web_app.app_service" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
import_resource_if_needed "module.backend.azurerm_key_vault_access_policy.policy" "$resourceId$providers"
providers="/providers/Microsoft.Web/sites/$appName|$appName"
import_resource_if_needed "module.backend.azurerm_monitor_diagnostic_setting.diagnostic_logs" "$resourceId$providers"


# Enrichment App
echo
figlet "Enrichment App"
appServicePlanName="infoasst-enrichmentasp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
import_resource_if_needed "module.enrichmentApp.azurerm_service_plan.appServicePlan" "$resourceId$providers"
providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
import_resource_if_needed "module.enrichmentApp.azurerm_monitor_autoscale_setting.scaleout" "$resourceId$providers"
appName="infoasst-enrichmentweb-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
import_resource_if_needed "module.enrichmentApp.azurerm_linux_web_app.app_service" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
import_resource_if_needed "module.enrichmentApp.azurerm_key_vault_access_policy.policy" "$resourceId$providers"
providers="/providers/Microsoft.Web/sites/$appName|example"
import_resource_if_needed "module.enrichmentApp.azurerm_monitor_diagnostic_setting.example" "$resourceId$providers"


# Storage 
echo
figlet "Storage"
TF_VAR_name="infoasststore$random_text"
providers="/providers/Microsoft.Storage/storageAccounts/$TF_VAR_name"
import_resource_if_needed "module.storage.azurerm_storage_account.storage" "$resourceId$providers"

url="https://$TF_VAR_name.blob.core.windows.net/content"
import_resource_if_needed "module.storage.azurerm_storage_container.container[0]" "$url"
url="https://$TF_VAR_name.blob.core.windows.net/website"
import_resource_if_needed "module.storage.azurerm_storage_container.container[1]" "$url"
url="https://$TF_VAR_name.blob.core.windows.net/upload"
import_resource_if_needed "module.storage.azurerm_storage_container.container[2]" "$url"
url="https://$TF_VAR_name.blob.core.windows.net/function"
import_resource_if_needed "module.storage.azurerm_storage_container.container[3]" "$url"
url="https://$TF_VAR_name.blob.core.windows.net/logs"
import_resource_if_needed "module.storage.azurerm_storage_container.container[4]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/pdf-submit-queue"

import_resource_if_needed "module.storage.azurerm_storage_queue.queue[0]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/pdf-polling-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[1]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/non-pdf-submit-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[2]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/media-submit-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[3]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/text-enrichment-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[4]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/image-enrichment-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[5]" "$url"
url="https://$TF_VAR_name..queue.core.windows.net/embeddings-queue"
import_resource_if_needed "module.storage.azurerm_storage_queue.queue[6]" "$url"

secret_id=$(get_secret "BLOB-CONNECTION-STRING")
import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_connection_string" "$secret_id"
secret_id=$(get_secret "AZURE-BLOB-STORAGE-KEY")
import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_connection_string" "$secret_id"


# Cosmos DB 
echo
figlet "Cosmos DB"
TF_VAR_name="infoasst-cosmos-$random_text"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name"
import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_account.cosmosdb_account" "$resourceId$providers"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name/sqlDatabases/statusdb"
import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_sql_database.log_database" "$resourceId$providers"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$TF_VAR_name/sqlDatabases/statusdb/containers/statuscontainer"
import_resource_if_needed "module.cosmosdb.azurerm_cosmosdb_sql_container.log_container" "$resourceId$providers"
secret_id=$(get_secret "COSMOSDB-KEY")
import_resource_if_needed "module.storage.azurerm_key_vault_secret.storage_connection_string" "$secret_id"


# Search Service
echo
figlet "Search Service"
TF_VAR_name="infoasst-search-$random_text"
providers="/providers/Microsoft.Search/searchServices/$TF_VAR_name"
import_resource_if_needed "module.searchServices.azurerm_search_service.search" "$resourceId$providers"
secret_id=$(get_secret "AZURE-SEARCH-SERVICE-KEY")
import_resource_if_needed "module.searchServices.azurerm_key_vault_secret.search_service_key" "$secret_id"

