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

# Display the notice
echo "IMPORTANT NOTICE:"
echo "Please read the following terms carefully. You must accept the terms to proceed."
echo
echo "This script will import the existing resources into the Terraform state."
echo "You may then run a MAKE DEPLOY on this environment to deploy the latest version"
echo "of the agent template while maintaining your existing resources and processed data."
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


#  Get the new and old envrironment values
FILE_PATH="$DIR/upgrade_repoint.config.json"
new_random_text=$(jq -r '.new_env.random_text' $FILE_PATH)
subscription=$TF_VAR_subscriptionId
random_text=$(echo "$new_random_text" | tr '[:upper:]' '[:lower:]')

echo "random_text: $random_text"
echo "TF_VAR_resource_group_name: $TF_VAR_resource_group_name"

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
# providers="/providers/Microsoft.Resources/deployments/pid-$TF_VAR_cuaId"
# module_path="azurerm_resource_group_template_deployment.customer_attribution" 
# import_resource_if_needed $module_path "$resourceId$providers"


# Entra 
echo
figlet "Entra"
webAccessApp_name="infoasst_web_access_$random_text"
# webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].application_id" --all | jq -r '.[0]')
webAccessApp_objectId=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
module_path="module.entraObjects.azuread_application.aad_web_app[0]"
import_resource_if_needed $module_path "/applications/$webAccessApp_objectId"


# Logging
echo
figlet "Logging"
name="infoasst-la-$random_text"
providers="/providers/Microsoft.OperationalInsights/workspaces/$name"
module_path="module.logging.azurerm_log_analytics_workspace.logAnalytics"
import_resource_if_needed $module_path "$resourceId$providers"
name="infoasst-ai-$random_text"
providers="/providers/Microsoft.Insights/components/$name"
module_path="module.logging.azurerm_application_insights.applicationInsights"
import_resource_if_needed $module_path "$resourceId$providers"



# OpenAI Services
echo
figlet "OpenAI Services"

if [ $TF_VAR_useExistingAOAIService = "false" ]; then
    name="infoasst-aoai-$random_text"
    providers="/providers/Microsoft.CognitiveServices/accounts/$name"
    module_path="module.openaiServices.azurerm_cognitive_account.account[0]"
    import_resource_if_needed $module_path "$resourceId$providers"

    if [ -z "$TF_VAR_chatGptDeploymentName" ]; then
        model_name="gpt-35-turbo-16k"
    else
        model_name=$TF_VAR_chatGptDeploymentName
    fi
    providers="/providers/Microsoft.CognitiveServices/accounts/$name/deployments/$model_name"
    module_path="module.openaiServices.azurerm_cognitive_deployment.deployment[0]"
    import_resource_if_needed $module_path "$resourceId$providers"

    providers="/providers/Microsoft.CognitiveServices/accounts/$name/deployments/$TF_VAR_azureOpenAIEmbeddingDeploymentName"
    module_path="module.openaiServices.azurerm_cognitive_deployment.deployment[1]"
    import_resource_if_needed $module_path "$resourceId$providers"

else
    echo -e "\e[34mService $name not found in resource group $TF_VAR_resource_group_name.\e[0m"
fi

secret_id=$(get_secret "AZURE-OPENAI-SERVICE-KEY")
module_path="module.openaiServices.azurerm_key_vault_secret.openaiServiceKeySecret"
import_resource_if_needed "$module_path" "$secret_id"


# AZ Monitor
# This is not deployed as part of 1.0, but in case ininital upgrade fails, we need to import it
# echo
# figlet "Az Monitor"
# providers="/providers/Microsoft.Insights/workbooks/85b3e8bb-fc93-40be-83f2-98f6bec18ba0"
# module_path="module.azMonitor.azurerm_application_insights_workbook.example"
# import_resource_if_needed $module_path "$resourceId$providers"


# System identity, user and management Roles
echo
figlet "Roles"

# Retrieve principal ids
sp_infoasst_mgmt_access=$(az ad sp list --filter "displayName eq 'infoasst_mgmt_access_$random_text'" --query "[].id" --output tsv)
sp_infoasst_func=$(az ad sp list --filter "displayName eq 'infoasst-func-$random_text'" --query "[].id" --output tsv)
sp_infoasst_enrichmentweb=$(az ad sp list --filter "displayName eq 'infoasst-enrichmentweb-$random_text'" --query "[].id" --output tsv)
sp_infoasst_web=$(az ad sp list --filter "displayName eq 'infoasst-web-$random_text'" --query "[].id" --output tsv)

echo "sp_infoasst_mgmt_access: $sp_infoasst_mgmt_access"
echo "sp_infoasst-func: $sp_infoasst_func"
echo "sp_infoasst-enrichmentweb: $sp_infoasst_enrichmentweb"
echo "sp_infoasst-web-: $sp_infoasst_web"

# Retrieve the role assignments for the resource group
output=$(az role assignment list \
  --subscription $TF_VAR_subscriptionId \
  --resource-group $TF_VAR_resource_group_name \
  --query "[].{roleDefinitionName: roleDefinitionName, id: id, principalId: principalId}" \
  --output json)

# Loop through each role assignment in the output and import
echo "$output" | jq -c '.[]' | while read -r line; do
    # Extract 'roleDefinitionName' and 'id' from the output
    roleDefinitionName=$(echo $line | jq -r '.roleDefinitionName' | tr -d ' ')
    roleId=$(echo $line | jq -r '.id')
    rolePrincipalId=$(echo $line | jq -r '.principalId')
    module_path=""
    if [ "$sp_infoasst_web" == "$rolePrincipalId" ]; then
        if [ "$roleDefinitionName" == "SearchIndexDataReader" ]; then
            module_path="module.searchRoleBackend.azurerm_role_assignment.role" 
        elif [ "$roleDefinitionName" == "CognitiveServicesOpenAIUser" ]; then
            module_path="module.openAiRoleBackend.azurerm_role_assignment.role"  
        elif [ "$roleDefinitionName" == "StorageBlobDataReader" ]; then
            module_path="module.storageRoleBackend.azurerm_role_assignment.role"   
        fi  
    elif [ "$sp_infoasst_func" == "$rolePrincipalId" ];  then
        if [ "$roleDefinitionName" == "StorageBlobDataReader" ]; then
            module_path="module.storageRoleFunc.azurerm_role_assignment.role"   
        fi
    # elif [ "$sp_infoasst_enrichmentweb" == "$rolePrincipalId" ]; then
    #     if [ "$roleDefinitionName" == "AcrPull" ]; then
    #         # no roles assigned to this service principal
    #     fi
    elif [ "$sp_infoasst_mgmt_access" == "$rolePrincipalId" ]; then
        # no roles assigned to this service principal
        if [ "$roleDefinitionName" == "CognitiveServicesOpenAIUser" ]; then
            module_path="module.openAiRoleMgmt[0].azurerm_role_assignment.role"   
        fi
    else
        # This is a user role
        if [ "$roleDefinitionName" == "StorageBlobDataReader" ]; then
            module_path="module.userRoles[\"StorageBlobDataReader\"].azurerm_role_assignment.role"
        # elif [ "$roleDefinitionName" == "AcrPush" ]; then
        #     # role not assigned here
        elif [ "$roleDefinitionName" == "SearchIndexDataContributor" ]; then
            module_path="module.userRoles[\"SearchIndexDataContributor\"].azurerm_role_assignment.role"  
        elif [ "$roleDefinitionName" == "CognitiveServicesOpenAIUser" ]; then
            module_path="module.userRoles[\"CognitiveServicesOpenAIUser\"].azurerm_role_assignment.role"
        elif [ "$roleDefinitionName" == "SearchIndexDataReader" ]; then
            module_path="module.userRoles[\"SearchIndexDataReader\"].azurerm_role_assignment.role"
        elif [ "$roleDefinitionName" == "StorageBlobDataContributor" ]; then
            module_path="module.userRoles[\"StorageBlobDataContributor\"].azurerm_role_assignment.role"
        fi
    fi
    if [ "$module_path" != "" ]; then
        import_resource_if_needed "$module_path" "$roleId"
    else
        echo "Unaccounted for role: "
        echo "roleDefinitionName: $roleDefinitionName"
        echo "roleId: $roleId"
        echo "rolePrincipalId: $rolePrincipalId"    
    fi
done

# If leveraging an existing Azure OpenAI service, read in the management service role
if [ "$TF_VAR_useExistingAOAIService" == "true" ]; then

    # get the role assignment for the webapp
    output=$(az role assignment list \
        --subscription $TF_VAR_subscriptionId \
        --resource-group $TF_VAR_azureOpenAIResourceGroup \
        --query "[?roleDefinitionName=='Cognitive Services OpenAI User' && principalId=='$sp_infoasst_mgmt_access'].{roleDefinitionName: roleDefinitionName, id: id, principalId: principalId}" \
        --output json)
    id=$(echo $output | jq -r '.[0].id')    
    module_path="module.openAiRoleMgmt[0].azurerm_role_assignment.role"
    if [ -n "$id" ]; then
        import_resource_if_needed "$module_path" "$id"
    fi

    # get the role assignment for the management app
    output=$(az role assignment list \
        --subscription $TF_VAR_subscriptionId \
        --resource-group $TF_VAR_azureOpenAIResourceGroup \
        --query "[?roleDefinitionName=='Cognitive Services OpenAI User' && principalId=='$sp_infoasst_web'].{roleDefinitionName: roleDefinitionName, id: id, principalId: principalId}" \
        --output json)
    id=$(echo $output | jq -r '.[0].id') 
    module_path="module.openAiRoleBackend.azurerm_role_assignment.role"
    if [ -n "$id" ]; then
        import_resource_if_needed "$module_path" "$id"
    fi  
fi


# appName="infoasst-web-$random_text"
appName="infoasst_web_access_$random_text"
module_path="module.entraObjects.azuread_service_principal.aad_web_sp[0]"
service_principal_id=$(az ad sp list --display-name "$appName" --query "[].id" | jq -r '.[0]')
import_resource_if_needed $module_path $service_principal_id

webAccessApp_name="infoasst_mgmt_access_$random_text"
webAccessApp_id=$(az ad app list --filter "displayName eq '$webAccessApp_name'" --query "[].id" --all | jq -r '.[0]')
module_path="module.entraObjects.azuread_application.aad_mgmt_app[0]"
import_resource_if_needed $module_path "/applications/$webAccessApp_id"

# *************************************************************
# This resource is not suppoprted through import via terraform
# "azuread_application_password" "aad_mgmt_app_password"
# *************************************************************

sp_name="infoasst_mgmt_access_$random_text"
sp_id=$(az ad sp list --display-name $sp_name --query "[].id" --output tsv)
module_path="module.entraObjects.azuread_service_principal.aad_mgmt_sp[0]"
import_resource_if_needed $module_path "$sp_id"


# Form Recognizer
echo
figlet "Form Recognizer"
name="infoasst-fr-$random_text"
providers="/providers/Microsoft.CognitiveServices/accounts/$name"
module_path="module.formrecognizer.azurerm_cognitive_account.formRecognizerAccount" 
import_resource_if_needed "$module_path" "$resourceId$providers"

# Cognitive Services 
echo
figlet "Cognitive Services"
name="infoasst-enrichment-cog-$random_text"
providers="/providers/Microsoft.CognitiveServices/accounts/$name"
module_path="module.cognitiveServices.azurerm_cognitive_account.cognitiveService"
import_resource_if_needed "$module_path" "$resourceId$providers"
secret_id=$(get_secret "AZURE-AI-KEY")
module_path="module.cognitiveServices.azurerm_key_vault_secret.search_service_key"
import_resource_if_needed "$module_path" "$secret_id"

# Key Vault
echo
figlet "Key Vault"
keyVaultId="infoasst-kv-$random_text"
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId"
module_path="module.kvModule.azurerm_key_vault.kv"
import_resource_if_needed "$module_path" "$resourceId$providers"
current_user_id=$(az ad signed-in-user show --query id -o tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$current_user_id"
module_path="module.kvModule.azurerm_key_vault_access_policy.infoasst"
import_resource_if_needed "$module_path" "$resourceId$providers"


# Functions
echo
figlet "Functions"
appServicePlanName="infoasst-func-asp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
module_path="module.functions.azurerm_service_plan.funcServicePlan"
import_resource_if_needed "$module_path" "$resourceId$providers"
appName="infoasst-func-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
module_path="module.functions.azurerm_linux_function_app.function_app"
import_resource_if_needed "$module_path" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
appId=$(az ad sp list --display-name "$appName" --query "[?displayName == '$appName'].id | [0]" --all --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$appId"
module_path="module.functions.azurerm_key_vault_access_policy.policy"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName-Autoscale"
module_path="module.functions.azurerm_monitor_autoscale_setting.scaleout"
import_resource_if_needed "$module_path" "$resourceId$providers"


# Web App
echo
figlet "Web App"
appServicePlanName="infoasst-asp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
module_path="module.backend.azurerm_service_plan.appServicePlan"
import_resource_if_needed "$module_path" "$resourceId$providers"
appName="infoasst-web-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
module_path="module.backend.azurerm_linux_web_app.app_service"
import_resource_if_needed "$module_path" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
appId=$(az ad sp list --display-name "$appName" --query "[?displayName == '$appName'].id | [0]" --all --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$appId"
module_path="module.backend.azurerm_key_vault_access_policy.policy"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.Web/sites/$appName|$appName"
module_path="module.backend.azurerm_monitor_diagnostic_setting.diagnostic_logs"
import_resource_if_needed "$module_path" "$resourceId$providers"


# Enrichment App
echo
figlet "Enrichment App"
appServicePlanName="infoasst-enrichmentasp-$random_text"
providers="/providers/Microsoft.Web/serverFarms/$appServicePlanName"
module_path="module.enrichmentApp.azurerm_service_plan.appServicePlan"
import_resource_if_needed "$module_path" "$resourceId$providers"
appName="infoasst-enrichmentweb-$random_text"
providers="/providers/Microsoft.Web/sites/$appName"
module_path="module.enrichmentApp.azurerm_linux_web_app.app_service"
import_resource_if_needed "$module_path" "$resourceId$providers"
keyVaultId="infoasst-kv-$random_text"
appId=$(az ad sp list --display-name "$appName" --query "[?displayName == '$appName'].id | [0]" --all --output tsv)
providers="/providers/Microsoft.KeyVault/vaults/$keyVaultId/objectId/$appId"
module_path="module.enrichmentApp.azurerm_key_vault_access_policy.policy"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.Web/sites/$appName|$appName"
module_path="module.enrichmentApp.azurerm_monitor_diagnostic_setting.diagnostic_setting"
import_resource_if_needed "$module_path" "$resourceId$providers"
providers="/providers/Microsoft.Insights/autoScaleSettings/$appServicePlanName"
module_path="module.enrichmentApp.azurerm_monitor_autoscale_setting.scaleout"
import_resource_if_needed "$module_path" "$resourceId$providers"


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


# Search Service
echo
figlet "Search Service"
name="infoasst-search-$random_text"
providers="/providers/Microsoft.Search/searchServices/$name"
module_path="module.searchServices.azurerm_search_service.search" 
import_resource_if_needed "$module_path" "$resourceId$providers"

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

#Inject dependencies
echo "Current directory: $(pwd)"
cd ../scripts
echo "Current directory: $(pwd)"
python "inf-inject-dependencies.py"