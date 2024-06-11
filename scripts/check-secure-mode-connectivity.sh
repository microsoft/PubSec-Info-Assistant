# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

set -e

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"

dns_private_resolver_ip=$(jq -r '.DNS_PRIVATE_RESOLVER_IP.value' $DIR/../inf_output.json)
export DNS_PRIVATE_RESOLVER_IP=$dns_private_resolver_ip

figlet Check Connectivity

# PAUSE TO ALLOW FOR MANUAL SETUP OF VPN
if [[ "$SECURE_MODE" == "true" ]]; then
    echo "Connection from the client machine to the Information Assistant virtual network is required to continue the deployment."
    echo -e "Please configure your connectivity and ensure you are using the DNS resolver at $DNS_PRIVATE_RESOLVER_IP\n"
    while true; do
        read -p "Are you ready to continue (y/n)? " yn
        case $yn in
            [Yy]* ) 
                echo "Continuing with the deployment..."
                break;;  
            [Nn]* ) 
                echo "Exiting. Please configure your connectivity before continuing."
                exit 1;;  
            * ) 
                echo "Invalid input. Please answer yes (y) or no (n).";;
        esac
    done
fi