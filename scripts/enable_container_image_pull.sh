#!/bin/bash

RESOURCE_GROUP=$1
WEB_APP_NAME=$2

# Set the Container Image Pull configuration
az webapp vnet-integration list --resource-group "$RESOURCE_GROUP" --name "$WEB_APP_NAME" | jq -r '.[].name' | while read -r VNET_INTEGRATION_NAME; do
  az webapp vnet-integration update --resource-group "$RESOURCE_GROUP" --name "$WEB_APP_NAME" --vnet-integration-name "$VNET_INTEGRATION_NAME" --container-image-pull true
done