# Configuring your System for Development Containers

## Install the Pre-Requisite Software

Install the following software on the machine you will perform the deployment from:

>1. [Windows Store Ubuntu 22.04 LTS](https://apps.microsoft.com/store/detail/ubuntu-22042-lts/9PN20MSR04DW)
>2. [Docker Desktop](https://www.docker.com/products/docker-desktop)
>3. [Visual Studio Code](https://visualstudio.microsoft.com/downloads/)
>4. [Remote-Containers VS Code Extension](vscode:extension/ms-vscode-remote.remote-containers)
>5. [Git for Windows](https://gitforwindows.org/)

## Configure WSL2 Backend for Docker Containers

To enable **Developing inside a Container** you must configure the integration between Docker Desktop and Ubuntu on your machine.

>1. Launch Docker Desktop
>2. Open **Settings > General**. Make sure the *Use the WSL 2 based engine" is enabled.
>3. Navigate to **Settings > Resources > WSL INTEGRATION**.
>      - Ensure *Enable Integration with my default WSL distro" is enabled.
>      - Enable the Ubuntu-22.04 option.
>4. Select **Apply & Restart**

## Connect to Ubuntu WSL with VSCode

Now that Docker Desktop and Ubuntu are integrated, we want to Access the Ubuntu bash prompt from inside VSCode.

>1. Launch VSCode.
>2. Select **View > Terminal**. A new window should open along the bottom of the VSCode window.
>3. From this windows use the **Launch Profile** dropdown to open the **Ubuntu 22.04 (WSL)** terminal. ![image](images/vscode_terminal_windows.png)
>4. A bash prompt should open in the format `{username}@{machine_name}:/mnt/c/Users/{username}$`

Once this is complete, you are ready to configure Git for your Ubuntu WSL environment.

## Configure Git in Ubuntu WSL environment

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

## Install Azure CLI On WSL

In your Ubuntu 22.04(WSL) terminal from the previous step, follow the directions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux) to install Azure CLI.

---

This step is complete, please continue on to the next step [Configuring your Development Environment for PS Info Assistant](./development_environment.md) section and complete the next step.
