#!/bin/bash 
set -e

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'
}

VERSION=${1:-"$(get_latest_release hashicorp/terraform)"}
INSTALL_DIR=${2:-"$HOME/.local/bin"}
CMD=terraform
NAME=Terraform

echo -e "\e[34m»»» 📦 \e[32mInstalling \e[33m$NAME v$VERSION\e[0m ..."

curl -sSL "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip" -o /tmp/tf.zip
unzip /tmp/tf.zip -d /tmp > /dev/null
mkdir -p $INSTALL_DIR
mv /tmp/terraform $INSTALL_DIR
rm -f /tmp/tf.zip

echo -e "\n\e[34m»»» 💾 \e[32mInstalled to: \e[33m$(which $CMD)"
echo -e "\e[34m»»» 💡 \e[32mVersion details: \e[39m$($CMD --version)"