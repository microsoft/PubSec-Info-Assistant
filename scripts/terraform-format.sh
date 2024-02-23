#!/bin/bash
set -e

# Get the directory that this script is in so the script will work regardless
# of where the user calls it from. If the scripts or its targets are moved,
# these relative paths will need to be updated.
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -e "\n\n>>> Terraform Format (if this fails use 'terraform fmt' command to resolve"
terraform fmt -recursive $DIR/../infrastructure