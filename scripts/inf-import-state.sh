# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e


# ***********************************************************
# Guidance to a user
# ***********************************************************

# Clear the screen
clear

# Function to change text color to yellow
set_yellow_text() {
    tput setaf 3  # Set text color to yellow
}

# Function to reset text color
reset_text_color() {
    tput sgr0  # Reset text color
}

figlet Import Terraform State

# Set text color to yellow
set_yellow_text

# # Display the notice
# echo "IMPORTANT NOTICE:"
# echo "Please read the following terms carefully. You must accept the terms to proceed."
# echo
# echo "This script will import the existing resources into the Terraform state."
# echo "You may then run a MAKE DEPLOY on this environment to deploy the latest version"
# echo "of the accelerator while maintaining your existing resources and processed data."
# echo
# echo "If you have modified the infrastructure base this process will fail."
# echo "The simplest approach to deploy the latest version would be to perform"
# echo "a new deployment on a new resource group and reprocess your data"

# # Reset text color for input prompt
# reset_text_color
# echo
# echo "Do you accept these terms? (yes/no)"

# # Wait for the user's input
# while true; do
#     read -rp "Type 'yes' to accept: " answer
#     case $answer in
#         [Yy]* ) break;;
#         [Nn]* ) echo "You did not accept the terms. Exiting."; exit 1;;
#         * ) echo "Please answer yes or no.";;
#     esac
# done

# Continue with the script after acceptance
echo "You have accepted the terms. Proceeding with the script..."
# Your script's logic goes here


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
      terraform import "$module_path" "$resource_id"|| error_messages+=("$module_path")
    elif terraform state list | grep -q $module_path_escaped; then
      echo -e "\e[34mResource $module_path is already managed by Terraform\e[0m"
    else 
      # the module is not managed by terraform
      echo -e "\e[34mResource $module_path is not managed by Terraform. Importing $module_path\e[0m"
      terraform import "$module_path" "$resource_id" || error_messages+=("$module_path")
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
error_messages=()
resourceId="/subscriptions/$TF_VAR_subscriptionId/resourceGroups/$TF_VAR_resource_group_name"

# Random String
echo
figlet "Random String"
module_path="random_string.random" 
import_resource_if_needed $module_path $random_text


# Main
echo
figlet "Main"
module_path="azurerm_resource_group.rg"
import_resource_if_needed $module_path "$resourceId"
providers="/providers/Microsoft.Resources/deployments/pid-"
module_path="azurerm_resource_group_template_deployment.customer_attribution[0]" 
import_resource_if_needed $module_path "$resourceId$providers"


# Entra 
echo
figlet "Entra"
webAccessApp_name="infoasst_web_access_$random_text"
# webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].application_id" --all | jq -r '.[0]')
webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
module_path="module.entraObjects.azuread_application.aad_web_app[0]"
import_resource_if_needed $module_path "/applications/$webAccessApp_objectId"



# ************ THIS DOESN'T EXIST - infoasst-web-ks5si
# appName="infoasst-web-$random_text"
appName="infoasst_web_access_$random_text"
module_path="module.entraObjects.azuread_service_principal.aad_web_sp[0]"
service_principal_id=$(az ad sp list --display-name "$appName" --query "[].id" | jq -r '.[0]')



import_resource_if_needed $module_path $service_principal_id
webAccessApp_name="infoasst_mgmt_access_$random_text"
webAccessApp_id=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
module_path="module.entraObjects.azuread_application.aad_mgmt_app[0]"
import_resource_if_needed $module_path "/applications/$webAccessApp_id"


# # OpenAI Services
# echo
# figlet "OpenAI Services"
# name="infoasst-aoai-$random_text"
# # only import if the service exists in the RG
# serviceExists=$(az resource list --resource-group "$TF_VAR_resource_group_name" --query "[?name=='$name'] | [0].name" --output tsv)
# if [[ $serviceExists == $name ]]; then

#     providers="/providers/Microsoft.CognitiveServices/accounts/$name"
#     module_path="module.openaiServices.azurerm_cognitive_account.account"
#     import_resource_if_needed $module_path "$resourceId$providers"

#     providers="/providers/Microsoft.CognitiveServices/accounts/$name/deployments/$TF_VAR_chatGptDeploymentName"
#     module_path="module.openaiServices.azurerm_cognitive_deployment.deployment"
#     import_resource_if_needed "$module_path" "$resourceId$providers"

#     secret_id=$(get_secret "AZURE-OPENAI-SERVICE-KEY")
#     module_path="module.cognitiveServices.azurerm_key_vault_secret.openaiServiceKeySecret"
#     import_resource_if_needed "$module_path" "$secret_id"

# else
#     echo -e "\e[34mService $name not found in resource group $TF_VAR_resource_group_name.\e[0m"
# fi


# # Monitor
# echo
# figlet "Monitor"
# name="infoasst-lw--$random_text"
# workbook_name=$(az resource list --resource-group $TF_VAR_resource_group_name --resource-type "Microsoft.Insights/workbooks" --query "[?type=='Microsoft.Insights/workbooks'].name | [0]" -o tsv)
# providers="/providers/Microsoft.Insights/workbooks/$workbook_name"
# module_path="module.azMonitor.azurerm_application_insights_workbook.example"
# import_resource_if_needed $module_path "$resourceId$providers"


# # Video Indexer
# echo
# figlet "Video Indexer"
# # Pelase note: we do not import vi state as a hotfix was pushed to main to not deploy vi due to
# # changes in the service in azure.
# name="infoasststoremedia$random_text"
# providers="/providers/Microsoft.Storage/storageAccounts/$name"
# module_path="module.video_indexer.azurerm_storage_account.media_storage"
# import_resource_if_needed $module_path "$resourceId$providers"
# name="infoasst-ua-ident-$random_text"
# providers="/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$name"
# module_path="module.video_indexer.azurerm_user_assigned_identity.vi"
# import_resource_if_needed $module_path "$resourceId$providers"

# # Retrive the principal id used to identify which roles are matched to this module
# # roles are assigned elswhere in the code, and have an assigned principal id
# # in the user roles module, the porinipal id of the user doing the deployment is used
# # to work around this identify the principals used in the other modules and
# # and filter role assignments from here that do not match these id's
# principalId1=$(az ad sp list --display-name infoasst-web-$random_text --query "[].id" --output tsv)
# # Loop through each role assignment in the output and import
# echo "$output" | jq -c '.[]' | while read -r line; do
#     # Extract 'roleDefinitionName' and 'id' from the output
#     roleDefinitionName=$(echo $line | jq -r '.roleDefinitionName' | tr -d ' ')
#     roleId=$(echo $line | jq -r '.id')
#     rolePrincipalId=$(echo $line | jq -r '.principalId')
#     # Check if this principal id is in the list of excluded principals
#     # if not, then import this item
#     if [ "$rolePrincipalId" = "$principalId1" ]; then
#         # Check if the roleDefinitionName is in the list of selected roles
#         # Use pattern matching after removing spaces from roleDefinitionName
#         if [[ " ${selected_roles[*]} " =~ " ${roleDefinitionName// /} " ]]; then
#             module_path="module.video_indexer[\"$roleDefinitionName\"].azurerm_role_assignment.role"
#             import_resource_if_needed "$module_path" "$roleId"
#         fi
#     fi  
# done


# # Form Recognizer
# echo
# figlet "Form Recognizer"
# name="infoasst-fr-$random_text"
# providers="/providers/Microsoft.CognitiveServices/accounts/$name"
# module_path="module.formrecognizer.azurerm_cognitive_account.formRecognizerAccount" 
# import_resource_if_needed "$module_path" "$resourceId$providers"
# secret_id=$(get_secret "AZURE-FORM-RECOGNIZER-KEY")
# module_path="module.cognitiveServices.azurerm_key_vault_secret.docIntelligenceKey"
# import_resource_if_needed "$module_path" "$secret_id"


# # Cognitive Services 
# echo
# figlet "Cognitive Services"
# name="infoasst-enrichment-cog-$random_text"
# providers="/providers/Microsoft.CognitiveServices/accounts/$name"
# module_path="module.cognitiveServices.azurerm_cognitive_account.cognitiveService"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# secret_id=$(get_secret "ENRICHMENT-KEY")
# module_path="module.cognitiveServices.azurerm_key_vault_secret.search_service_key"
# import_resource_if_needed "$module_path" "$secret_id"


# # Logging
echo
figlet "Logging"
name="infoasst-ai-$random_text"
providers="/providers/Microsoft.Insights/components/$name"
module_path="module.logging.azurerm_application_insights.applicationInsights"
import_resource_if_needed "$module_path" "$resourceId$providers"


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
            module_path="module.userRoles[\"$roleDefinitionName\"].azurerm_role_assignment.role"
            import_resource_if_needed "$module_path" "$roleId"
        fi
    fi  
done


# Key Vault
echo
figlet "Key Vault"
keyVaultId="infoasst-kv-$random_text"
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId"
module_path="module.kvModule.azurerm_key_vault.kv"
import_resource_if_needed "$module_path" "$resourceId$providers"
secret_id=$(get_secret "AZURE-CLIENT-SECRET")
module_path="module.kvModule.azurerm_key_vault_secret.spClientKeySecret"
import_resource_if_needed "$module_path" "$secret_id"


# # Functions
# echo
# figlet "Functions"
# appServicePlanName="infoasst-func-asp-$random_text-Autoscale"
# providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
# module_path="module.functions.azurerm_service_plan.funcServicePlan"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
# module_path="module.functions.azurerm_monitor_autoscale_setting.scaleout"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# appName="infoasst-func-$random_text"
# providers="/providers/Microsoft.Web/sites/$appName"
# module_path="module.functions.azurerm_linux_function_app.function_app"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# keyVaultId="infoasst-kv-$random_text"
# objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
# providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
# module_path="module.functions.azurerm_key_vault_access_policy.policy"
# import_resource_if_needed "$module_path" "$resourceId$providers"


# # Web App
# echo
# figlet "Web App"
# appServicePlanName="infoasst-asp-$random_text"
# providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
# module_path="module.backend.azurerm_service_plan.appServicePlan"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# appName="infoasst-web-$random_text"
# providers="/providers/Microsoft.Web/sites/$appName"
# module_path="module.backend.azurerm_linux_web_app.app_service"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# keyVaultId="infoasst-kv-$random_text"
# objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
# providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
# module_path="module.backend.azurerm_key_vault_access_policy.policy"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# # providers="/providers/Microsoft.Web/sites/$appName|$appName"
# # import_resource_if_needed "module.backend.azurerm_monitor_diagnostic_setting.diagnostic_logs" "$resourceId$providers"


# # Enrichment App
# echo
# figlet "Enrichment App"
# appServicePlanName="infoasst-enrichmentasp-$random_text"
# providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
# module_path="module.enrichmentApp.azurerm_service_plan.appServicePlan"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
# module_path="module.enrichmentApp.azurerm_monitor_autoscale_setting.scaleout" 
# import_resource_if_needed "$module_path" "$resourceId$providers"
# appName="infoasst-enrichmentweb-$random_text"
# providers="/providers/Microsoft.Web/sites/$appName"
# module_path="module.enrichmentApp.azurerm_linux_web_app.app_service"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# keyVaultId="infoasst-kv-$random_text"
# objectId=$(az keyvault show --name $keyVaultId --resource-group $TF_VAR_resource_group_name --query "properties.accessPolicies[0].objectId" --output tsv)
# providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$objectId"
# module_path="module.enrichmentApp.azurerm_key_vault_access_policy.policy"
# import_resource_if_needed "$module_path" "$resourceId$providers"
# # providers="/providers/Microsoft.Web/sites/$appName|example"
# # import_resource_if_needed "module.enrichmentApp.azurerm_monitor_diagnostic_setting.example" "$resourceId$providers"


# Storage 
echo
figlet "Storage"
name="infoasststore$random_text"
providers="/providers/Microsoft.Storage/storageAccounts/$name"
module_path="module.storage.azurerm_storage_account.storage"
import_resource_if_needed "$module_path" "$resourceId$providers"

module_path="module.storage.azurerm_storage_container.container"
url="https://$name.blob.core.windows.net/content"
import_resource_if_needed "$module_path[0]" "$url"
url="https://$name.blob.core.windows.net/website"
import_resource_if_needed "$module_path[1]" "$url"
url="https://$name.blob.core.windows.net/upload"
import_resource_if_needed "$module_path[2]" "$url"
url="https://$name.blob.core.windows.net/function"
import_resource_if_needed "$module_path[3]" "$url"
url="https://$name.blob.core.windows.net/logs"
import_resource_if_needed "$module_path[4]" "$url"

module_path="module.storage.azurerm_storage_queue.queue"
url="https://$name.queue.core.windows.net/pdf-submit-queue"
import_resource_if_needed "$module_path[0]" "$url"
url="https://$name.queue.core.windows.net/pdf-polling-queue"
import_resource_if_needed "$module_path[1]" "$url"
url="https://$name.queue.core.windows.net/non-pdf-submit-queue"
import_resource_if_needed "$module_path[2]" "$url"
url="https://$name.queue.core.windows.net/media-submit-queue"
import_resource_if_needed "$module_path[3]" "$url"
url="https://$name.queue.core.windows.net/text-enrichment-queue"
import_resource_if_needed "$module_path[4]" "$url"
url="https://$name.queue.core.windows.net/image-enrichment-queue"
import_resource_if_needed "$module_path[5]" "$url"
url="https://$name.queue.core.windows.net/embeddings-queue"
import_resource_if_needed "$module_path[6]" "$url"

secret_id=$(get_secret "BLOB-CONNECTION-STRING")
module_path="module.storage.azurerm_key_vault_secret.storage_connection_string"
import_resource_if_needed "$module_path" "$secret_id"
secret_id=$(get_secret "AZURE-BLOB-STORAGE-KEY")
module_path="module.storage.azurerm_key_vault_secret.storage_key"
import_resource_if_needed "$module_path" "$secret_id"


# Cosmos DB 
echo
figlet "Cosmos DB"
name="infoasst-cosmos-$random_text"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$name"
module_path="module.cosmosdb.azurerm_cosmosdb_account.cosmosdb_account"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$name/sqlDatabases/statusdb"
module_path="module.cosmosdb.azurerm_cosmosdb_sql_database.log_database"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.DocumentDB/databaseAccounts/$name/sqlDatabases/statusdb/containers/statuscontainer"
module_path="module.cosmosdb.azurerm_cosmosdb_sql_container.log_container"
import_resource_if_needed "$module_path" "$resourceId$providers"
secret_id=$(get_secret "COSMOSDB-KEY")
module_path="module.storage.azurerm_key_vault_secret.cosmos_db_key"
import_resource_if_needed "$module_path" "$secret_id"



# Search Service
echo
figlet "Search Service"
name="infoasst-search-$random_text"
providers="/providers/Microsoft.Search/searchServices/$name"
module_path="module.searchServices.azurerm_search_service.search" 
import_resource_if_needed "$module_path" "$resourceId$providers"
secret_id=$(get_secret "AZURE-SEARCH-SERVICE-KEY")
module_path="module.searchServices.azurerm_key_vault_secret.search_service_key" 
import_resource_if_needed "$module_path" "$secret_id"


# Output log on imported services
echo
figlet "Output Log"
echo
echo -e "\e[34mBelow are the services now managed by terraform:\e[0m"
printf "\033[32m%s\033[0m\n" "$(terraform state list)"

echo
if [ ${#error_messages[@]} -ne 0 ]; then
    echo -e "\e[34mThe following service states were not imported:\e[0m"
    echo
    for msg in "${error_messages[@]}"; do
        echo -e "\033[31m$msg\033[0m"
    done
else
    echo "All commands executed successfully."
fi

echo
figlet "Done"