# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash
set -e

# Colours for stdout
YELLOW='\e[1;33m'
RESET='\e[0m'

printInfo() {
    printf "$YELLOW\n%s$RESET\n" "$1"
}

figlet Infrastructure Cleanup

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${DIR}/load-env.sh

pushd "$DIR/../infra" > /dev/null

# Initialise Terraform with the correct path
${DIR}/terraform-init.sh "$DIR/../infra"


# Delete the remote state
printInfo "Delete the workspace:"
terraform workspace select default
terraform workspace delete -force "${WORKSPACE}"

printInfo "Deleting the .terraform folder:"
rm -rf .terraform

printInfo "Deleting the .terraform plan:"
rm -rf infoasst.tfplan.txt

printInfo "Deleting the .terraform state lock:"
rm -rf .terraform.lock.hcl

exit $EXIT_CODE
