#!/bin/bash 
set -e

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
source $NVM_DIR/nvm.sh
nvm install v18.12.1