#!/bin/bash

ENV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# To maintain backward compatibility, we need to convert some of the variables to TF_VAR_ format
export TF_VAR_azureOpenAIResourceGroup=$AZURE_OPENAI_RESOURCE_GROUP
export TF_VAR_environmentName=$WORKSPACE
export TF_VAR_location=$LOCATION
export TF_VAR_useExistingAOAIService=$USE_EXISTING_AOAI
export TF_VAR_azureOpenAIServiceName=$AZURE_OPENAI_SERVICE_NAME
export TF_VAR_azureOpenAIServiceKey=$AZURE_OPENAI_SERVICE_KEY
export TF_VAR_tenantId=$TENANT_ID
export TF_VAR_azureOpenAIEmbeddingDeploymentName=$AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME
export TF_VAR_useAzureOpenAIEmbeddings=$USE_AZURE_OPENAI_EMBEDDINGS
export TF_VAR_sentenceTransformersModelName=$OPEN_SOURCE_EMBEDDING_MODEL
export TF_VAR_sentenceTransformerEmbeddingVectorSize=$OPEN_SOURCE_EMBEDDING_MODEL_VECTOR_SIZE
export TF_VAR_isGovCloudDeployment=$IS_USGOV_DEPLOYMENT
export TF_VAR_requireWebsiteSecurityMembership=$REQUIRE_WEBSITE_SECURITY_MEMBERSHIP