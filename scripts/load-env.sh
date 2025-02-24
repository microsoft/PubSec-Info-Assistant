# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/sh

#setting up necessary permissions to access the Docker daemon socket
sudo chmod 666 /var/run/docker.sock

# Set up all the required environment variables for the deployment
# Default values - you can override these using "azd env set"
# -------------------------------------------------------------------------------------------------------

deployment_machine_ip=""

# When in CI/CD pipeline mode...
if [ "$FROM_PIPELINE" = "true" ]; then
    
    deployment_public_ip=$(curl -s http://ipinfo.io/json | jq -r '.ip')

    echo "Deployment machine public IP: $deployment_machine_ip"

    # Set the build number that will be added to the tags of the Azure resources
    if [ -z "$BUILD_BUILDID" ]; then
        echo "Require BUILD_BUILDID to be set for CI builds"
        exit 1        
    fi
    azd env set BUILD_NUMBER "$BUILD_BUILDNUMBER"
else
    # Get the public IP of the current machine using OpenDNS
    deployment_machine_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

    # Check if the dig command returned an empty result 
    if [ -z "$deployment_machine_ip" ]; then 
        # Fallback to using icanhazip.com
        deployment_machine_ip=$(curl -s ipv4.icanhazip.com)
    fi
    azd env set BUILD_NUMBER "local"
fi


azd env set DEPLOYMENT_PUBLIC_IP $deployment_machine_ip
azd env get-values | grep DEPLOYMENT_PUBLIC_IP

echo "deployment machine public ip is " $deployment_machine_ip

if [ -z $AZURE_ENVIRONMENT ]; then
    echo "Azure Environment not set, defaulting to AzureCloud"
    azd env set AZURE_ENVIRONMENT AzureCloud
else
    echo "Azure Environment: $AZURE_ENVIRONMENT"
fi
if [ -z $USE_WEB_CHAT ]; then
    azd env set USE_WEB_CHAT true
fi
if [ -z $USE_BING_SAFE_SEARCH ]; then
    azd env set USE_BING_SAFE_SEARCH true
fi
if [ -z $USE_UNGROUNDED_CHAT ]; then
    azd env set USE_UNGROUNDED_CHAT false
fi
if [ -z $REQUIRE_WEBSITE_SECURITY_MEMBERSHIP ]; then
    azd env set REQUIRE_WEBSITE_SECURITY_MEMBERSHIP false
fi
if [ -z $SECRET_EXPIRATION_DAYS ]; then
    azd env set SECRET_EXPIRATION_DAYS 730
fi
if [ -z $EXISTING_AZURE_OPENAI_RESOURCE_GROUP ]; then
    azd env set EXISTING_AZURE_OPENAI_RESOURCE_GROUP ""
fi
if [ -z $EXISTING_AZURE_OPENAI_SERVICE_NAME ]; then
    azd env set EXISTING_AZURE_OPENAI_SERVICE_NAME ""
fi
if [ -z $EXISTING_AZURE_OPENAI_LOCATION ]; then
    azd env set EXISTING_AZURE_OPENAI_LOCATION ""
fi
if [ -z $AZURE_OPENAI_CHATGPT_DEPLOYMENT ]; then
    azd env set AZURE_OPENAI_CHATGPT_DEPLOYMENT "gpt-4o"
fi
if [ -z $AZURE_OPENAI_CHATGPT_MODEL_NAME ]; then
    azd env set AZURE_OPENAI_CHATGPT_MODEL_NAME ""
fi
if [ -z $AZURE_OPENAI_CHATGPT_MODEL_VERSION ]; then
    azd env set AZURE_OPENAI_CHATGPT_MODEL_VERSION ""
fi
if [ -z $AZURE_OPENAI_CHATGPT_SKU ]; then
    azd env set AZURE_OPENAI_CHATGPT_SKU "Standard"
fi
if [ -z $AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME ]; then
    azd env set AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME "text-embedding-ada-002"
fi
if [ -z $AZURE_OPENAI_EMBEDDINGS_MODEL_NAME ]; then
    azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_NAME ""
fi
if [ -z $AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION ]; then
    azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION ""
fi
if [ -z $AZURE_OPENAI_EMBEDDINGS_SKU ]; then
    azd env set AZURE_OPENAI_EMBEDDINGS_SKU "Standard"
fi
if [ -z $AZURE_OPENAI_CHATGPT_MODEL_CAPACITY ]; then
    azd env set AZURE_OPENAI_CHATGPT_MODEL_CAPACITY "240"
fi
if [ -z $AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY ]; then
    azd env set AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY "240"
fi
if [ -z $CHAT_WARNING_BANNER_TEXT ]; then
    azd env set CHAT_WARNING_BANNER_TEXT ""
fi
if [ -z $DEFAULT_LANGUAGE ]; then
    azd env set DEFAULT_LANGUAGE "en-US"
fi
if [ -z $USE_CUSTOMER_USAGE_ATTRIBUTION ]; then
    azd env set USE_CUSTOMER_USAGE_ATTRIBUTION true
fi
if [ -z ${CUSTOMER_USAGE_ATTRIBUTION_ID+x} ]; then
    azd env set CUSTOMER_USAGE_ATTRIBUTION_ID "7a01ff74-15c2-4fec-9f14-63db7d3d6131"
fi
if [ -z $APPLICATION_TITLE ]; then
    azd env set APPLICATION_TITLE ""
fi
if [ -z $ENTRA_OWNERS ]; then
    azd env set ENTRA_OWNERS ""
fi
if [ -z $SERVICE_MANAGEMENT_REFERENCE ]; then
    azd env set SERVICE_MANAGEMENT_REFERENCE ""
fi
if [ -z $PASSWORD_LIFETIME_DAYS ]; then
    azd env set PASSWORD_LIFETIME_DAYS 365
fi
if [ -z $USE_DDOS_PROTECTION_PLAN ]; then
    azd env set USE_DDOS_PROTECTION_PLAN false
fi
if [ -z $IN_AUTOMATION ]; then
    azd env set IN_AUTOMATION false
fi
if [ -z $USE_CUSTOM_ENTRA_OBJECTS ]; then
    azd env set USE_CUSTOM_ENTRA_OBJECTS false
fi
if [ -z $FROM_PIPELINE ]; then
    azd env set FROM_PIPELINE false
fi
if [ -z $PROMPT_QUERYTERM_LANGUAGE ]; then
    # The language that Azure OpenAI will be prompted to generate the search terms in
    azd env set PROMPT_QUERYTERM_LANGUAGE "English"
fi
if [ -z $SEARCH_INDEX_ANALYZER ]; then
    # The analyzer that the search index will used for all "searchable" fields
    azd env set SEARCH_INDEX_ANALYZER "standard.lucene"
fi
if [ -z $TARGET_TRANSLATION_LANGUAGE ]; then
    # Target language to translate text to
    azd env set TARGET_TRANSLATION_LANGUAGE "en"
fi
if [ -z $USE_CUSTOM_NETWORK_SETTINGS ]; then
    azd env set USE_CUSTOM_NETWORK_SETTINGS false
fi
if [ -z $SEARCH_SERVICE_SKU ]; then
    azd env set SEARCH_SERVICE_SKU "standard3"
fi
if [ -z $SEARCH_SERVICE_REPLICA_COUNT ]; then
    azd env set SEARCH_SERVICE_REPLICA_COUNT 3
fi
if [ -z $USE_NETWORK_SECURITY_PERIMETER ]; then
    azd env set USE_NETWORK_SECURITY_PERIMETER false
fi
if [ -z $STORE_TF_STATE_IN_AZURE ]; then
    azd env set STORE_TF_STATE_IN_AZURE false
fi  
# -------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------

# Get the defaults set above, as azd env set doesn't actively load the variable into memory
eval $(azd env get-values | sed 's/^/export /')

# Azure Cloud specific variables. These are the default values for AzureCloud
# -------------------------------------------------------------------------------------------------------
if [ $AZURE_ENVIRONMENT = "AzureCloud" ]; then
    azd env set arm_template_schema_mgmt_api "https://schema.management.azure.com"
    azd env set azure_portal_domain "https://portal.azure.com"
    azd env set azure_search_domain "search.windows.net"
    azd env set azure_search_scope "https://search.azure.com"
    azd env set use_semantic_reranker true
    azd env set azure_storage_domain "core.windows.net"
    azd env set azure_openai_domain "openai.azure.com"
    azd env set azure_openai_authority_host "AzureCloud"
    azd env set azure_sts_issuer_domain "sts.windows.net"
    azd env set azure_websites_domain "azurewebsites.net"
    azd env set azure_arm_management_api "https://management.azure.com"
    azd env set azure_keyvault_domain "vaultcore.azure.net"
    azd env set azure_monitor_domain "monitor.azure.com"
    azd env set azure_monitor_oms_domain "oms.opinsights.azure.com"
    azd env set azure_monitor_ods_domain "ods.opinsights.azure.com"
    azd env set azure_automation_domain "azure-automation.net"
    azd env set azure_ai_document_intelligence_domain "cognitiveservices.azure.com"
    azd env set azure_bing_search_domain "api.bing.microsoft.com"
    azd env set azure_ai_private_link_domain "cognitiveservices.azure.com"
elif [ $AZURE_ENVIRONMENT = "AzureUSGovernment" ]; then
    azd env set arm_template_schema_mgmt_api "https://schema.management.usgovcloudapi.net"
    azd env set azure_portal_domain "https://portal.azure.us"
    azd env set azure_search_domain "search.azure.us"
    azd env set azure_search_scope "https://search.azure.us"
    azd env set use_semantic_reranker true
    azd env set azure_storage_domain "core.usgovcloudapi.net"
    azd env set azure_openai_domain "openai.azure.us"
    azd env set azure_openai_authority_host "AzureUSGovernment"
    azd env set azure_sts_issuer_domain "login.microsoftonline.us"
    azd env set azure_websites_domain "azurewebsites.us"
    azd env set azure_arm_management_api "https://management.usgovcloudapi.net"
    azd env set azure_keyvault_domain "vaultcore.usgovcloudapi.net"
    azd env set azure_monitor_domain "monitor.azure.us"
    azd env set azure_monitor_oms_domain "oms.opinsights.azure.us"
    azd env set azure_monitor_ods_domain "ods.opinsights.azure.us"
    azd env set azure_automation_domain "azure-automation.us"
    azd env set azure_ai_document_intelligence_domain "cognitiveservices.azure.us"
    azd env set azure_bing_search_domain "" #blank as Bing Search in not available in Azure Government
    azd env set azure_ai_private_link_domain "cognitiveservices.azure.us"
fi
# -------------------------------------------------------------------------------------------------------

# Check for invalid combinations of feature flags and environment variables
# -------------------------------------------------------------------------------------------------------
# Fail if the user has set USE_WEB_CHAT to true and the AZURE_ENVIRONMENT to AzureUSGovernment
if [ "$USE_WEB_CHAT" = "true" ] && [ $AZURE_ENVIRONMENT = "AzureUSGovernment" ]; then
    echo "\e[31mWeb Chat is not available on AzureUSGovernment deployments. Check your values for USE_WEB_CHAT and AZURE_ENVIRONMENT.\e[0m\n"
    exit 1
fi

# Check to see if an existing Azure Open AI service was provided and warn the user before proceeding with the deployment
if [ -z "$EXISTING_AZURE_OPENAI_RESOURCE_GROUP" ] && [ -z "$EXISTING_AZURE_OPENAI_SERVICE_NAME" ] && [ -z "$EXISTING_AZURE_OPENAI_LOCATION" ]; then
    # All are empty or null, continue the process
    :
elif [ -n "$EXISTING_AZURE_OPENAI_RESOURCE_GROUP" ] && [ -n "$EXISTING_AZURE_OPENAI_SERVICE_NAME" ] && [ -n "$EXISTING_AZURE_OPENAI_LOCATION" ]; then
    # All are populated, raise a warning and ask for confirmation
    echo "\n"
    echo "\033[33mWARNING: Azure Open AI service $EXISTING_AZURE_OPENAI_SERVICE_NAME in resource group: $EXISTING_AZURE_OPENAI_RESOURCE_GROUP was specified. This deployment will attempt to secure this deployment and can impact any service already using this Azure Open AI instance. This is not a reversible action.\033[0m"
    echo "Do you want to continue? (y/n): \c"
    read choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo "Process aborted by user."
        exit 1
    fi
    echo "\n"
    echo "Checking the existing Azure Open AI service..."
    aoai_service_location=$(az cognitiveservices account show --name "$EXISTING_AZURE_OPENAI_SERVICE_NAME" --resource-group "$EXISTING_AZURE_OPENAI_RESOURCE_GROUP" -o tsv --query "location")
    if [ "$aoai_service_location" != "$EXISTING_AZURE_OPENAI_LOCATION" ]; then
        echo "\033[33mWARNING: The specified Azure Open AI service $EXISTING_AZURE_OPENAI_SERVICE_NAME is in a different location than you provided. This will destroy and recreate the service.\033[0m"
        echo "Do you want to continue? (y/n): \c"
        read choice
        if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
            echo "Process aborted by user."
            exit 1
        fi
    fi
else
    # Only one is populated, raise an error
    echo "\033[31mERROR: Either both EXISTING_AZURE_OPENAI_RESOURCE_GROUP and EXISTING_AZURE_SERVICE_NAME must be populated, or neither. Please check your azd environment variables.\033[0m"
    exit 1
fi

# Check for existing DDOS Protection Plan and use it if available
if [ "$USE_DDOS_PROTECTION_PLAN" = "true" ]; then
  if [ -z "$DDOS_PLAN_ID" ]; then
      # No DDOS_PLAN_ID provided in the environment, look up Azure for an existing DDOS plan
      DDOS_PLAN_ID=$(az network ddos-protection list --query "[?contains(name, 'ddos')].id | [0]" --output tsv)
      
      if [ -z "$DDOS_PLAN_ID" ]; then
          echo "\e[31mNo existing DDOS protection plan found. Terraform will create a new one.\n\e[0m"
      else
          echo "Found existing DDOS Protection Plan: $DDOS_PLAN_ID"
          read -p "Do you want to use this existing DDOS Protection Plan (y/n)? " use_existing
          if [ "$use_existing" =~ ^[Yy]$ ]; then
              echo "Using existing DDOS Protection Plan: $DDOS_PLAN_ID\n"
              azd env set DDOS_PLAN_ID $DDOS_PLAN_ID

              echo "-------------------------------------\n"
              echo "DDOS_PLAN_ID is set to: $DDOS_PLAN_ID"
              echo "-------------------------------------\n"

          else
              azd env set DDOS_PLAN_ID ""  # Clear the variable to indicate that a new plan should be created
              echo "A new DDOS Protection Plan will be created by Terraform."
          fi
      fi
  else
      echo "Using provided DDOS Protection Plan ID from environment: $DDOS_PLAN_ID\n"
      azd env set DDOS_PLAN_ID $DDOS_PLAN_ID
  fi
else
    echo "DDOS Protection Plan is disabled. No DDOS Protection Plan will be created."
    azd env set DDOS_PLAN_ID ""
fi
# -------------------------------------------------------------------------------------------------------

# Convert the comma-separated list of owners to an Azure Entra IDs to pass into Terraform
object_ids=""
# Remove spaces from the comma-separated string
ENTRA_OWNERS=$(echo "$ENTRA_OWNERS" | tr -d ' ')
IFS=','
set -- $ENTRA_OWNERS
for user_principal_name in "$@"; do
  object_id=$(az ad user list --filter "mail eq '$user_principal_name'" --query "[0].id" -o tsv)
  # Check if the object_id is not empty before adding it to the list
  if [ -n "$object_id" ]; then
    object_ids="$object_ids $object_id"
    echo "user_principal_name: $user_principal_name and object_id: $object_id to be added as an owner"
  else
    echo "No object_id found for user_principal_name: $user_principal_name"
  fi
done
# Join the space-separated string of object IDs into a comma-separated string
object_ids_string=$(echo "$object_ids" | sed 's/^ *//' | tr ' ' ',')
azd env set ENTRA_OWNER_OBJECT_IDS "$object_ids_string"

if [ "$STORE_TF_STATE_IN_AZURE" = "true" ]; then
    # Set terraform to use remote backend to store the tfstate files. 
    if [ -n "$AZURE_ENVIRONMENT" ] && [ "$AZURE_ENVIRONMENT" = "AzureUSGovernment" ]; then
        cp ./infra/backend.tf.us.ci ./infra/backend.tf
    else
        cp ./infra/backend.tf.ci ./infra/backend.tf
    fi
    # The following values need to be provided as pipeline variables
    # TF_BACKEND_RESOURCE_GROUP
    # TF_BACKEND_STORAGE_ACCOUNT
    # TF_BACKEND_CONTAINER
    echo "{
        \"storage_account_name\": \"$TF_BACKEND_STORAGE_ACCOUNT\",
        \"container_name\": \"$TF_BACKEND_CONTAINER\",
        \"resource_group_name\": \"$TF_BACKEND_RESOURCE_GROUP\",
        \"key\": \"shared.infoasst.tfstate:$AZURE_ENV_NAME\"
    }" > ./infra/provider.conf.json
else
    # Set terraform to use local backend to store the tfstate files.
    rm ./infra/backend.tf
    # ensure the provider.conf.json file is deleted
    rm ./infra/provider.conf.json
fi

# If the USE_CUSTOM_ENTRA_OBJECTS flag is set, use the manually created AD objects for the deployment
if [ "$USE_CUSTOM_ENTRA_OBJECTS" = "true" ]; then  
    # if set to use custom entra objects, the following variables must be set in the azd environment
    if [ -z "$AAD_WEB_CLIENT_ID" ]; then
        echo "An Azure AD App Registration and Service Principal must be manually created for the targeted workspace."
        echo "Please create the Azure AD objects using the documents at docs/deployment/manual_app_registration.md and set the AAD_WEB_CLIENT_ID azd environment variable."
        exit 1  
    fi
    if [ -z "$AAD_MGMT_CLIENT_ID" ]; then
        echo "An Azure AD App Registration and Service Principal must be manually created for the targeted workspace."
        echo "Please create the Azure AD objects using the documents at docs/deployment/manual_app_registration.md and set the AAD_MGMT_CLIENT_ID azd environment variable."
        exit 1  
    fi
    if [ -z "$AAD_MGMT_SP_ID" ]; then
        echo "An Azure AD App Registration and Service Principal must be manually created for the targeted workspace."
        echo "Please create the Azure AD objects using the documents at docs/deployment/manual_app_registration.md and set the AAD_MGMT_SP_ID azd environment variable."
        exit 1
    fi
fi

# Set the name of the resource group
azd env set RESOURCE_GROUP_NAME "infoasst-$AZURE_ENV_NAME"

# The default key that is used in the remote state
azd env set TF_BACKEND_STATE_KEY "shared.infoasst.tfstate"

# Subscription ID mandatory for Terraform AzureRM provider 4.x.x https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide#specifying-subscription-id-is-now-mandatory
azd env set ARM_SUBSCRIPTION_ID "$AZURE_SUBSCRIPTION_ID"

# The below syntax takes the current date and adds the number of days as set in the SECRET_EXPIRATION_DAYS environment variable.
kv_secret_expiration=$(date -d "+$SECRET_EXPIRATION_DAYS days" --utc +%Y-%m-%dT%H:%M:%SZ)
azd env set kv_secret_expiration "$kv_secret_expiration"
echo "Key Vault secret expiration date set to: $(date -d @$kv_secret_expiration)"

# Ensure all variables set above are loaded into memory, 
# as azd env set doesn't actively load the variable into memory
eval $(azd env get-values | sed 's/^/export /')

# Report out the target resource group
echo "\n\e[32m🎯 Target Resource Group: \e[33m$RESOURCE_GROUP_NAME\e[0m\n"