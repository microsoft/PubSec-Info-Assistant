FROM mcr.microsoft.com/vscode/devcontainers/python:0-3.10-bullseye

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
RUN sudo apt-get update \
    && sudo apt-get -y install --no-install-recommends apt-utils dialog nano bash-completion sudo bsdmainutils cmake \
    #
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed
    && sudo apt-get -y install git iproute2 procps lsb-release figlet build-essential

# Save command line history
RUN echo "export HISTFILE=/home/$USERNAME/commandhistory/.bash_history" >> "/home/$USERNAME/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/home/$USERNAME/.bashrc" \
    && mkdir -p /home/$USERNAME/commandhistory \
    && touch /home/$USERNAME/commandhistory/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/commandhistory

# docker-client
RUN sudo apt-get update \
    # libgl dependencies and install Docker CE CLI
    && sudo apt-get install ffmpeg libsm6 libxext6 apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release -y \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo apt-key add - 2>/dev/null \
    && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && sudo apt-get update \
    && sudo apt-get install -y docker-ce-cli 

ARG DOCKER_GROUP_ID
COPY ./scripts/docker-client.sh /tmp/
RUN /tmp/docker-client.sh $USERNAME

# Git command prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"$HOME/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && source $HOME/.bash-git-prompt/gitprompt.sh; fi" >> "/home/$USERNAME/.bashrc"

# terraform + tflint
ARG TERRAFORM_VERSION=1.3.7
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

# azure-cli
COPY ./scripts/azure-cli.sh /tmp/
RUN /tmp/azure-cli.sh

# Install dotnet 6 & Azure Functions Core Tools
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/microsoft.list \
    && echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list \
    && wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y azure-functions-core-tools-4

# Install Powershell
RUN apt-get update \
    && apt-get install -y powershell \
    # Alias Powershell
    && echo "alias powershell=pwsh" >> "/home/$USERNAME/.bashrc"

#Install npm and nodejs in the Docker dev container
COPY ./scripts/nodejs.sh /tmp/
RUN /tmp/nodejs.sh

# Sync timezone (if TZ value not already present on host it defaults to Europe/London)
# Note: if running on WSL (Windows) you can add the below to your $profile so your tz is automatically synced
# $tz =  [Windows.Globalization.Calendar,Windows.Globalization,ContentType=WindowsRuntime]::New().GetTimeZone()
# [Environment]::SetEnvironmentVariable("TZ",$tz, "User")
RUN if [ -z "$TZ" ]; then TZ="Europe/London"; fi && sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ | sudo tee /etc/timezone > /dev/null

# Install gettext-base so that we have envsubst
RUN sudo apt-get update \
    && sudo apt-get -y install gettext-base