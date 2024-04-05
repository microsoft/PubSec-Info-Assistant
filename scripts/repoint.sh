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
echo

# core values
new_resource_group="infoasst-geearl-3421-v1.1"
new_random_text="bwncp"
old_resource_group="infoasst-geearl-212-v1.0"
old_random_text="rgx3o"
subscription="0d4b9684-ad97-4326-8ed0-df8c5b780d35"





#############################################################
figlet "Role Access"
# Grant role access to resources in old rpesource group"

# Retrieve principal ids
sp_infoasst_mgmt_access=$(az ad sp list --filter "displayName eq 'infoasst_mgmt_access_$new_random_text'" --query "[].appId" --output tsv)
sp_infoasst_func=$(az ad sp list --filter "displayName eq 'infoasst-func-$new_random_text'" --query "[].id" --output tsv)
sp_infoasst_enrichmentweb=$(az ad sp list --filter "displayName eq 'infoasst-enrichmentweb-$new_random_text'" --query "[].id" --output tsv)
sp_infoasst_web=$(az ad sp list --filter "displayName eq 'infoasst-web-$new_random_text'" --query "[].id" --output tsv)
echo "sp_infoasst_mgmt_access: $sp_infoasst_mgmt_access"
echo "sp_infoasst-func: $sp_infoasst_func"
echo "sp_infoasst-enrichmentweb: $sp_infoasst_enrichmentweb"
echo "sp_infoasst-web-: $sp_infoasst_web"

az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Search Index Data Contributor" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Search Index Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_mgmt_access" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_func" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_web" --role "Search Index Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"
az role assignment create --assignee "$sp_infoasst_web" --role "Storage Blob Data Reader" --scope "/subscriptions/$subscription/resourceGroups/$old_resource_group"


#############################################################
figlet "Functions Configuration"
function_app_name="infoasst-func-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_CONNECTION_STRING"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/BLOB-CONNECTION-STRING)"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_STORAGE_ACCOUNT_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="BLOB_STORAGE_ACCOUNT_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$function_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null


#############################################################
figlet "Web App Configuration"
web_app_name="infoasst-web-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE"
setting_value="infoasst-search-$old_random_text"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_tex.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$functioweb_app_namen_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$web_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null


#############################################################
figlet "Enrichment App Configuration"
enrichment_app_name="infoasst-enrichmentweb-$new_random_text"

setting_key="AZURE_BLOB_STORAGE_ACCOUNT"
setting_value="infoasststore$old_random_text"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_ENDPOINT"
setting_value="https://infoasststore$old_random_text.blob.core.windows.net/"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_BLOB_STORAGE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-BLOB-STORAGE-KEY)"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE"
setting_value="infoasst-search-$old_random_text"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_ENDPOINT"
setting_value="https://infoasst-search-$old_random_text.search.windows.net/"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_SEARCH_SERVICE_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/AZURE-SEARCH-SERVICE-KEY)"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="AZURE_STORAGE_CONNECTION_STRING"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/BLOB-CONNECTION-STRING)"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_KEY"
setting_value="@Microsoft.KeyVault(SecretUri=https://infoasst-kv-$old_random_text.vault.azure.net/secrets/COSMOSDB-KEY)"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null

setting_key="COSMOSDB_URL"
setting_value="https://infoasst-cosmos-$old_random_text.documents.azure.com:443/"
az functionapp config appsettings set --name "$enrichment_app_name" --resource-group "$new_resource_group" --settings "$setting_key=$setting_value" > /dev/null
