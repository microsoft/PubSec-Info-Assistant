# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

USERNAME=${1:-"automatic"}
USER_UID=${2:-"automatic"}
USER_GID=${3:-"automatic"}

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
  for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
    if id -u ${CURRENT_USER} > /dev/null 2>&1; then
      USERNAME=${CURRENT_USER}
      break
    fi
  done
  if [ "${USERNAME}" = "" ]; then
    USERNAME=vscode
  fi
elif [ "${USERNAME}" = "none" ]; then
  USERNAME=root
  USER_UID=0
  USER_GID=0
fi

if id -u ${USERNAME} > /dev/null 2>&1; then
  if [ "${USER_GID}" != "automatic" ] && [ "${USER_GID}" != "999" ] && [ "$USER_GID" != "$(id -G $USERNAME)" ]; then 
    groupmod --gid $USER_GID $USERNAME 
    usermod --gid $USER_GID $USERNAME
  fi
  if [ "${USER_UID}" != "automatic" ] && [ "${USER_GID}" != "999" ] && [ "$USER_UID" != "$(id -u $USERNAME)" ]; then 
    usermod --uid $USER_UID $USERNAME
  fi
else
  if [ "${USER_GID}" = "automatic" ]; then
    groupadd $USERNAME
  else
    groupadd --gid $USER_GID $USERNAME
  fi
  if [ "${USER_UID}" = "automatic" ]; then 
    useradd -s /bin/bash --gid $USERNAME -m $USERNAME
  else
    useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME
  fi
fi

if [ "${USERNAME}" != "root" ]; then
  mkdir -p /etc/sudoers.d
  echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
  chmod 0440 /etc/sudoers.d/$USERNAME
fi

#Explanation
#Non-Root User Setup: Creating or updating a non-root user to match UID/GID.
#Sudo Support: Adding sudo support for the non-root user.