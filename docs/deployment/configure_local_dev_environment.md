# Configuring your System for Development Containers

* [Getting started with development containers](#getting-started-development-containers)
* [Install the Prerequisite Software](#Install-the-prerequisite-software)
* [Setting up Docker Desktop for Windows with WSL 2](#setting-up-docker-desktop-for-Windows-with-WSL-2)
  * [Configure WSL2 Backend for Docker Containers](#configure-wsl2-backend-for-docker-containers)
  * [Connect to Ubuntu WSL with VSCode](#Connect-to-ubuntu-wsl-with-vscode)
  * [Configure Git in Ubuntu WSL environment](#configure-Git-in-Ubuntu-WSL-environment)
* [Install Azure CLI on WSL](#install-azure-cli-on-wsl)
* [Configure Local Development Environment](configure-local-development-environment)

---
## Getting started with development containers
The Visual Studio Code Dev Containers extension lets you use a container as a full-featured development environment. It allows you to open any folder inside (or mounted into) a container and take advantage of Visual Studio Code's full feature set. A devcontainer.json file in your project tells VS Code how to access (or create) a development container with a well-defined tool and runtime stack. This container can be used to run an application or to separate tools, libraries, or runtimes needed for working with a codebase.

*More information can be found at [Developing inside a Container](https://code.visualstudio.com/docs/remote/containers).*

---
## Install the Pre-Requisite Software

Install the following software on the machine you will perform the deployment from:

>1. [Windows Store Ubuntu 22.04 LTS](https://apps.microsoft.com/store/detail/ubuntu-22042-lts/9PN20MSR04DW)
>2. [Docker Desktop](https://www.docker.com/products/docker-desktop)
>3. [Visual Studio Code](https://visualstudio.microsoft.com/downloads/)
>4. [Remote-Containers VS Code Extension](vscode:extension/ms-vscode-remote.remote-containers)
>5. [Git for Windows](https://gitforwindows.org/)

---

## Setting up Docker Desktop for Windows with WSL 2

Docker Desktop for Windows provides a development environment for building, shipping, and running dockerized apps. By enabling the WSL 2 based engine, you can run both Linux and Windows containers in Docker Desktop on the same machine.

### Configure WSL2 Backend for Docker Containers

To enable **Developing inside a Container** you must configure the integration between Docker Desktop and Ubuntu on your machine.

>1. Launch Docker Desktop
>2. Open **Settings > General**. Make sure the *Use the WSL 2 based engine" is enabled.
>3. Navigate to **Settings > Resources > WSL INTEGRATION**.
>      - Ensure *Enable Integration with my default WSL distro" is enabled.
>      - Enable the Ubuntu-22.04 option.
>4. Select **Apply & Restart**


### Connect to Ubuntu WSL with VSCode

Now that Docker Desktop and Ubuntu are integrated, we want to Access the Ubuntu bash prompt from inside VSCode.

>1. Launch VSCode.
>2. Select **View > Terminal**. A new window should open along the bottom of the VSCode window.
>3. From this windows use the **Launch Profile** dropdown to open the **Ubuntu 22.04 (WSL)** terminal. ![image](images/vscode_terminal_windows.png)
>4. A bash prompt should open in the format `{username}@{machine_name}:/mnt/c/Users/{username}$`

Once this is complete, you are ready to configure Git for your Ubuntu WSL environment.


### Configure Git in Ubuntu WSL environment

The next step is to configure Git for your Ubuntu WSL environment. We will use the bash prompt from the previous step to issue the following commands:

Set Git User Name and Email

``` bash
    git config --global user.name "Your Name"
    git config --global user.email "youremail@yourdomain.com"
```

Set Git [UseHttps](https://github.com/microsoft/Git-Credential-Manager-Core/blob/main/docs/configuration.md#credentialusehttppath)

``` bash
    git config --global credential.useHttpPath true
```

Configure Git to use the Windows Host Credential Manager

``` bash
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager-core.exe"
```

---
## Install Azure CLI On WSL

In your Ubuntu 22.04(WSL) terminal from the previous step, follow the directions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux) to install Azure CLI.

---

## Configure Local Development Environment

Follow these steps to get the accelerator up and running in a subscription of your choice.

### Clone Repo

The first step will be to clone the Git repo into your Ubuntu 18.04 WSL environment and, for production deployments, checkout the version that you would like to deploy. For development, stay on main and checkout an appropriate branch. To do this:

>1. In GitHub, on the Source Tab select **<> Code** and get the HTTPS Clone path.
>2. Launch VSCode. Open the Ubunut 22.04(WSL) Terminal.
>3. Run the following command from the bash command prompt
>
>   ``` bash
>       git clone <repo url> info-assist
>       cd info-assist
>       git fetch --tags
>       git checkout tags/<version>
>   ```
>

This will now have created the **info-assist** folder on your Ubuntu 22.04 WSL environemnt.

---

### Open Code in Development Container

The next step is to open the source code and build the dev container. To do this you will:

1. Log into Azure using the Azure CLI
2. Open the cloned source code into VSCode
3. Launch and connect to the development container from VSCode

---
### Important: Rebuild Development container


 When using any new version of Info Assistant code base from the repo, be sure to rebuild your development container.

 A new popup should appear in VS Code to rebuild the container. If the popup does not appear you can also do the following:

- Control + Shift + P
- Type Rebuild and select "Dev Containers: Rebuild Container"

---
This step is complete, please continue on to the next step [Configuring your Development Environment for PS Info Assistant](./development_environment.md) section and complete the next step.

