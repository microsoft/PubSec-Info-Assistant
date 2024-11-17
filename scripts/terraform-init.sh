# Copyright (c) DataReason.
### Code for On-Premises Deployment.

#!/bin/bash
set -e

# This script initializes Terraform in a given directory

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Argument parsing
function show_usage() {
  echo "terraform-init.sh [DIR]"
  echo
  echo "Initialize terraform in a particular directory"
}

# Process switches
if [[ $# -eq 1 ]]; then
  TERRAFORM_DIR=$1
else
  show_usage
  exit 1
fi

pushd "$TERRAFORM_DIR" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

terraform init -backend-config="path=$TERRAFORM_DIR/terraform.tfstate"

workspace_exists=$(terraform workspace list | grep -qE "\s${WORKSPACE}$"; echo $?)
if [[ "$workspace_exists" == "0" ]]; then
  terraform workspace select ${WORKSPACE}
else
  terraform workspace new ${WORKSPACE}
fi

#Explanation
#Local State: Using local state files instead of remote backends.
#Initialization: Initializing Terraform with the local state file path.
#Workspace Management: Managing Terraform workspaces locally.