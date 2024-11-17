# Copyright (c) DataReason.
### Code for On-Premises Deployment.


#!/bin/bash
set -e

if [ -z "$DOCKER_GROUP_ID" ]; then
  groupadd docker
else
  groupadd -g $DOCKER_GROUP_ID docker
fi

usermod -aG docker $1 && newgrp docker
getent group docker

#Explanation
#Docker Group: Creating the Docker group and adding the user to it.