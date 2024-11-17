# Copyright (c) DataReason.
### Code for On-Premises Deployment.

#!/bin/bash
set -e

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
source $NVM_DIR/nvm.sh
nvm install v20.13.0

#Explanation
#NVM Installation: Installing Node Version Manager (NVM).
#Node.js Installation: Using NVM to install Node.js version 20.13.0.