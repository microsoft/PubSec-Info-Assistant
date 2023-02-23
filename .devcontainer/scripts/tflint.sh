#!/bin/bash

# Install TFlint
LATEST_VERSION=$(curl --silent "https://api.github.com/repos/terraform-linters/tflint/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
VERSION=${VERSION:-$LATEST_VERSION}

if [[ -d ~/.local/bin ]]; then
    mkdir -p ~/.local/bin
    echo "export PATH=$PATH:~/.local/bin" >> ~/.bashrc
fi

curl -sSL -o /tmp/tflint.zip https://github.com/terraform-linters/tflint/releases/download/${VERSION}/tflint_linux_amd64.zip
unzip /tmp/tflint.zip -d /tmp
mv /tmp/tflint ~/.local/bin/
rm /tmp/tflint.zip
