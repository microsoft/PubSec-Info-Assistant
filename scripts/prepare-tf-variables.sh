# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/sh

# Load the environment variables
. ./scripts/load-env.sh

# Load the environment variables into a tfvars.json file

# Extract the value of ENTRA_OWNER_OBJECT_IDS
ENTRA_OWNER_OBJECT_IDS_VALUE=$(azd env get-values --output json | jq -r '.ENTRA_OWNER_OBJECT_IDS')

echo "{
    \"environmentName\": \"$AZURE_ENV_NAME\",
    \"location\": \"$AZURE_LOCATION\",
    \"buildNumber\": \"$BUILD_NUMBER\",
    \"useCUA\": \"$USE_CUSTOMER_USAGE_ATTRIBUTION\",
    \"cuaId\": \"$CUSTOMER_USAGE_ATTRIBUTION_ID\",
    \"requireWebsiteSecurityMembership\": \"$REQUIRE_WEBSITE_SECURITY_MEMBERSHIP\",
    \"azure_sts_issuer_domain\": \"$azure_sts_issuer_domain\",
    \"useBingSafeSearch\": \"$USE_BING_SAFE_SEARCH\",
    \"useWebChat\": \"$USE_WEB_CHAT\",
    \"useUngroundedChat\": \"$USE_UNGROUNDED_CHAT\",
    \"useNetworkSecurityPerimeter\": \"$USE_NETWORK_SECURITY_PERIMETER\",
    \"azure_environment\": \"$AZURE_ENVIRONMENT\",
    \"azure_websites_domain\": \"$azure_websites_domain\",
    \"azure_portal_domain\": \"$azure_portal_domain\",
    \"azure_openai_domain\": \"$azure_openai_domain\",
    \"azure_openai_authority_host\": \"$azure_openai_authority_host\",
    \"azure_arm_management_api\": \"$azure_arm_management_api\",
    \"azure_search_domain\": \"$azure_search_domain\",
    \"azure_search_scope\": \"$azure_search_scope\",
    \"use_semantic_reranker\": \"$use_semantic_reranker\",
    \"azure_storage_domain\": \"$azure_storage_domain\",
    \"arm_template_schema_mgmt_api\": \"$arm_template_schema_mgmt_api\",
    \"azure_monitor_domain\": \"$azure_monitor_domain\",
    \"azure_monitor_ods_domain\": \"$azure_monitor_ods_domain\",
    \"azure_monitor_oms_domain\": \"$azure_monitor_oms_domain\",
    \"azure_automation_domain\": \"$azure_automation_domain\",
    \"azure_keyvault_domain\": \"$azure_keyvault_domain\",
    \"azure_ai_document_intelligence_domain\": \"$azure_ai_document_intelligence_domain\",
    \"azure_bing_search_domain\": \"$azure_bing_search_domain\",
    \"azure_ai_private_link_domain\": \"$azure_ai_private_link_domain\",
    \"existingAzureOpenAIServiceName\": \"$EXISTING_AZURE_OPENAI_SERVICE_NAME\",
    \"existingAzureOpenAIResourceGroup\": \"$EXISTING_AZURE_OPENAI_RESOURCE_GROUP\",
    \"existingAzureOpenAILocation\": \"$EXISTING_AZURE_OPENAI_LOCATION\",
    \"chatGptDeploymentName\": \"$AZURE_OPENAI_CHATGPT_DEPLOYMENT\",
    \"chatGptModelName\": \"$AZURE_OPENAI_CHATGPT_MODEL_NAME\",
    \"chatGptModelVersion\": \"$AZURE_OPENAI_CHATGPT_MODEL_VERSION\",
    \"chatGptModelSkuName\": \"$AZURE_OPENAI_CHATGPT_SKU\",
    \"chatGptDeploymentCapacity\": \"$AZURE_OPENAI_CHATGPT_MODEL_CAPACITY\",
    \"azureOpenAIEmbeddingDeploymentName\": \"$AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME\",
    \"azureOpenAIEmbeddingsModelName\": \"$AZURE_OPENAI_EMBEDDINGS_MODEL_NAME\",
    \"azureOpenAIEmbeddingsModelSku\": \"$AZURE_OPENAI_EMBEDDINGS_SKU\",
    \"azureOpenAIEmbeddingsModelVersion\": \"$AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION\",
    \"embeddingsDeploymentCapacity\": \"$AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY\",
    \"ddos_plan_id\": \"$DDOS_PLAN_ID\",
    \"kv_secret_expiration\": \"$kv_secret_expiration\",
    \"useDDOSProtectionPlan\": \"$USE_DDOS_PROTECTION_PLAN\",
    \"searchServicesSkuName\": \"$SEARCH_SERVICE_SKU\",
    \"searchServicesReplicaCount\": \"$SEARCH_SERVICE_REPLICA_COUNT\",
    \"chatWarningBannerText\": \"$CHAT_WARNING_BANNER_TEXT\",
    \"queryTermLanguage\": \"$PROMPT_QUERYTERM_LANGUAGE\",
    \"targetTranslationLanguage\": \"$TARGET_TRANSLATION_LANGUAGE\",
    \"applicationtitle\": \"$APPLICATION_TITLE\",
    \"entraOwners\": \"$ENTRA_OWNER_OBJECT_IDS_VALUE\",
    \"useCustomEntra\": \"$USE_CUSTOM_ENTRA_OBJECTS\",
    \"serviceManagementReference\": \"$SERVICE_MANAGEMENT_REFERENCE\",
    \"password_lifetime\": \"$PASSWORD_LIFETIME_DAYS\",
    \"deployment_public_ip\": \"$DEPLOYMENT_PUBLIC_IP\"
}" > ./infra/main.tfvars.json

# If USE_CUSTOM_ENTRA_OBJECTS append the custom object ids to the main.tfvars.json
if [ "$USE_CUSTOM_ENTRA_OBJECTS" = "true" ]; then
    # Read the existing JSON content
    json_content=$(cat ./infra/main.tfvars.json)

    # Remove the closing brace
    json_content=$(echo "$json_content" | sed 's/}$//')

    # Append the new key-value pair
    json_content=$(cat <<EOF
        $json_content,
        "aadWebClientId": "$AAD_WEB_CLIENT_ID",
        "aadMgmtClientId": "$AAD_MGMT_CLIENT_ID",
        "aadMgmtServicePrincipalId": "$AAD_MGMT_SP_ID"
        }
EOF
)
    # Write the updated JSON content back to the file
    echo "$json_content" > ./infra/main.tfvars.json
fi

# If USE_CUSTOM_NETWORK_SETTINGS append the custom network settings to the main.tfvars.json
if [ "$USE_CUSTOM_NETWORK_SETTINGS" = "true" ]; then
    # Read the existing JSON content
    json_content=$(cat ./infra/main.tfvars.json)

    # Remove the closing brace
    json_content=$(echo "$json_content" | sed 's/}$//')

    # Append the new key-value pair
    json_content=$(cat <<EOF
        $json_content,
        "virtual_network_CIDR": "$VNET_NETWORK_CIDR",
        "azure_monitor_CIDR": "$VNET_MONITOR_CIDR",
        "storage_account_CIDR": "$VNET_STORAGE_ACCOUNT_CIDR",
        "azure_ai_CIDR": "$VNET_AI_CIDR",
        "webapp_CIDR": "$VNET_WEBAPP_CIDR",
        "key_vault_CIDR": "$VNET_KEYVAULT_CIDR",
        "search_service_CIDR": "$VNET_SEARCH_SERVICE_CIDR",
        "bing_service_CIDR": "$VNET_BING_SERVICE_CIDR",
        "azure_openAI_CIDR": "$VNET_OPENAI_CIDR",
        "integration_CIDR": "$VNET_INTEGRATION_CIDR",
        "dns_CIDR": "$VNET_DNS_CIDR",
        }
EOF
)
    # Write the updated JSON content back to the file
    echo "$json_content" > ./infra/main.tfvars.json
fi

cat ./infra/main.tfvars.json
