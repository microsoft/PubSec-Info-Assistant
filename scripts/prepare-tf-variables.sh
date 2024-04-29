# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

ENV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# To maintain backward compatibility, we need to convert some of the variables to TF_VAR_ format
export TF_VAR_environmentName=$WORKSPACE
export TF_VAR_location=$LOCATION
export TF_VAR_tenantId=$TENANT_ID
export TF_VAR_subscriptionId=$SUBSCRIPTION_ID
export TF_VAR_useExistingAOAIService=$USE_EXISTING_AOAI
export TF_VAR_azureOpenAIResourceGroup=$AZURE_OPENAI_RESOURCE_GROUP
export TF_VAR_azureOpenAIServiceName=$AZURE_OPENAI_SERVICE_NAME
export TF_VAR_azureOpenAIServiceKey=$AZURE_OPENAI_SERVICE_KEY
export TF_VAR_chatGptDeploymentName=$AZURE_OPENAI_CHATGPT_DEPLOYMENT
export TF_VAR_chatGptModelName=$AZURE_OPENAI_CHATGPT_MODEL_NAME
export TF_VAR_chatGptModelVersion=$AZURE_OPENAI_CHATGPT_MODEL_VERSION
export TF_VAR_chatGptDeploymentCapacity=$AZURE_OPENAI_CHATGPT_MODEL_CAPACITY
export TF_VAR_embeddingsDeploymentCapacity=$AZURE_OPENAI_EMBEDDINGS_MODEL_CAPACITY
export TF_VAR_azureOpenAIEmbeddingDeploymentName=$AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME
export TF_VAR_useAzureOpenAIEmbeddings=$USE_AZURE_OPENAI_EMBEDDINGS
export TF_VAR_azureOpenAIEmbeddingsModelName=$AZURE_OPENAI_EMBEDDINGS_MODEL_NAME
export TF_VAR_azureOpenAIEmbeddingsModelVersion=$AZURE_OPENAI_EMBEDDINGS_MODEL_VERSION
export TF_VAR_sentenceTransformersModelName=$OPEN_SOURCE_EMBEDDING_MODEL
export TF_VAR_sentenceTransformerEmbeddingVectorSize=$OPEN_SOURCE_EMBEDDING_MODEL_VECTOR_SIZE
export TF_VAR_requireWebsiteSecurityMembership=$REQUIRE_WEBSITE_SECURITY_MEMBERSHIP
export TF_VAR_queryTermLanguage=$PROMPT_QUERYTERM_LANGUAGE
export TF_VAR_targetTranslationLanguage=$TARGET_TRANSLATION_LANGUAGE
export TF_VAR_applicationtitle=$APPLICATION_TITLE
export TF_VAR_chatWarningBannerText=$CHAT_WARNING_BANNER_TEXT
export TF_VAR_cuaEnabled=$ENABLE_CUSTOMER_USAGE_ATTRIBUTION
export TF_VAR_cuaId=$CUSTOMER_USAGE_ATTRIBUTION_ID
export TF_VAR_enableDevCode=$ENABLE_DEV_CODE
export TF_VAR_video_indexer_api_version=$VIDEO_INDEXER_API_VERSION
export TF_VAR_azure_environment=$AZURE_ENVIRONMENT
export TF_VAR_is_secure_mode=$SECURE_MODE
export TF_VAR_enableBingSafeSearch=$ENABLE_BING_SAFE_SEARCH
export TF_VAR_azure_environment=$AZURE_ENVIRONMENT
export TF_VAR_enableWebChat=$ENABLE_WEB_CHAT
export TF_VAR_enableUngroundedChat=$ENABLE_UNGROUNDED_CHAT
export TF_VAR_enableMathAssitant=$ENABLE_MATH_ASSISTANT
export TF_VAR_enableTabularDataAssistant=$ENABLE_TABULAR_DATA_ASSISTANT
export TF_VAR_enableSharePointConnector=$ENABLE_SHAREPOINT_CONNECTOR
export TF_VAR_enableMultimedia=$ENABLE_MULTIMEDIA
export TF_VAR_maxCsvFileSize=$MAX_CSV_FILE_SIZE
export TF_VAR_userIpAddress=$USER_IP_ADDRESS