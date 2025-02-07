# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash 
set -e

if [ -z "$DOCKER_GROUP_ID" ]; then
    sudo groupadd docker
else
    sudo groupadd -g $DOCKER_GROUP_ID docker
fi

sudo usermod -aG docker $1 && newgrp docker
getent group docker