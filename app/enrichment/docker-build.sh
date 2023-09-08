# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

figlet Docker "Build Docker"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/../../scripts/load-env.sh"

sudo docker build -t enrichment-app ${DIR} --build-arg BUILDKIT_INLINE_CACHE=1
tag=$(date -u +"%Y%m%d-%H%M%S")
sudo docker tag enrichment-app enrichment-app:${tag}

# Output the tag so we can use it in the deployment
echo -n $tag > "${DIR}/image_tag.txt"

# Note on use of `sudo`
# To avoid docker-in-docker, we're reusing the /var/run/docker.sock socket from the host.
# On the host, permission to access the docker socket is typically controlled by membership
# of the `docker` group. For that to work here, we need the `vscode` user in the dev container
# to be a member of a group with the same group id (GID) as the GID for the `docker` group 
# on the host.
# In a (non-exhaustive) survey of people on the team we found 115, 998, 999, and 1001 as
# values for the GID for the `docker` group.
# As an alternative to keep the portability of the dev container, we are using `sudo` to 
# run elevated when performing docker commands.
# Since the `az acr login` command also manipulates docker, it needs to run elevated as well.
# To support this, the host user's `.azure` folder is mapped in twice, once to /home/vscode/.azure
# and a second time to /root/.azure. This ensures that the CLI can be invoked with or without
# sudo and still pick up the user credentials