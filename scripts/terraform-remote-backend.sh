# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

if [ -n "${AZURE_ENVIRONMENT}" ] && [[ "$AZURE_ENVIRONMENT" == "AzureUSGovernment" ]]; then
    mv ./infra/backend.tf.us.ci ./infra/backend.tf
else
    mv ./infra/backend.tf.ci ./infra/backend.tf
fi