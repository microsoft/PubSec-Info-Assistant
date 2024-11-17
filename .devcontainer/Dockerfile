# Copyright (c) DataReason.
### Code for On-Premises Deployment.

FROM mcr.microsoft.com/vscode/devcontainers/python:3.10-bookworm

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set up non-root user
COPY ./scripts/non-root-user.sh /tmp/
RUN bash "/tmp/non-root-user.sh" "${USERNAME}" "${USER_UID}" "${USER_GID}"

# Set env for tracking that we're running in a devcontainer
ENV DEVCONTAINER=true

# Configure apt, install packages and general tools
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog nano bash-completion sudo bsdmainutils cmake \
    && apt-get -y install git iproute2 procps lsb-release figlet build-essential dnsutils openvpn

# Save command line history
RUN echo "export HISTFILE=/home/$USERNAME/commandhistory/.bash_history" >> "/home/$USERNAME/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/home/$USERNAME/.bashrc" \
    && mkdir -p /home/$USERNAME/commandhistory \
    && touch /home/$USERNAME/commandhistory/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/commandhistory

# Install Docker CLI
RUN apt-get update \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update -y \
    && apt-get install -y docker-ce-cli

ARG DOCKER_GROUP_ID
COPY ./scripts/docker-client.sh /tmp/
RUN /tmp/docker-client.sh $USERNAME

# Git command prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"$HOME/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && source $HOME/.bash-git-prompt/gitprompt.sh; fi" >> "/home/$USERNAME/.bashrc"

# Install Terraform and TFLint
ARG TERRAFORM_VERSION=1.8.5
ARG TFLINT_VERSION=0.44.1
RUN mkdir -p /tmp/docker-downloads \
    && curl -sSL -o /tmp/docker-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip /tmp/docker-downloads/terraform.zip \
    && mv terraform /usr/local/bin \
    && rm /tmp/docker-downloads/terraform.zip \
    && echo "alias tf=terraform" >> "/home/$USERNAME/.bashrc"
RUN curl -sSL -o /tmp/docker-downloads/tflint.zip https://github.com/wata727/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip /tmp/docker-downloads/tflint.zip \
    && mv tflint /usr/local/bin \
    && rm /tmp/docker-downloads/tflint.zip

# Install Azure CLI
COPY ./scripts/azure-cli.sh /tmp/
RUN /tmp/azure-cli.sh

# Install Azure Functions Core Tools
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/microsoft.list \
    && echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list \
    && wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y azure-functions-core-tools-4

# Install Node.js and npm
COPY ./scripts/nodejs.sh /tmp/
RUN /tmp/nodejs.sh

# Sync timezone
RUN if [ -z "$TZ" ]; then TZ="Europe/London"; fi && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install gettext-base for envsubst
RUN apt-get update \
    && apt-get -y install gettext-base

# Install Python packages for migration
RUN pip install azure-cosmos pyfiglet azure-identity azure-keyvault-secrets

# Install Python package for backend testing
RUN pip install pytest

# Install skopeo
RUN DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install usrmerge \
    && echo 'deb http://ftp.debian.org/debian trixie main' | tee /etc/apt/sources.list.d/debian.trixie.list \
    && apt-get update \
    && apt-get install skopeo

#Explanation
#Base Image: Using the official VSCode Python devcontainer image.
#Non-Interactive Mode: Setting DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation.
#Non-Root User: Setting up a non-root user.
#Command Line History: Configuring command line history.
#Docker CLI: Installing Docker CLI.
#Git Prompt: Installing Git command prompt.
#Terraform and TFLint: Installing Terraform and TFLint.
#Azure CLI: Installing Azure CLI.
#Azure Functions Core Tools: Installing Azure Functions Core Tools.
#Node.js and npm: Installing Node.js and npm.
#Timezone Sync: Syncing timezone.
#Gettext: Installing gettext-base for envsubst.
#Python Packages: Installing necessary Python packages.
#Skopeo: Installing skopeo for container image management.