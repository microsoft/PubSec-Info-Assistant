# Developing in a GitHub Codespaces
You can develop code in a codespace using your choice of tool:

>- A command shell, via an SSH connection initiated using GitHub CLI.
>- One of the JetBrains IDEs, via the JetBrains Gateway.
>- The Visual Studio Code desktop application.
>- A browser-based version of Visual Studio Code.

## Creating your codespace

1.	Click on [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/microsoft/PubSec-Info-Assistant)
2.	New window will open where you can create a new codespace
3.	By default, you will be on **main** branch, you can switch to specific branch where you would like to create a codespace.
    Also it would provide option to select **Region**,**Machine type**
5.	Then click on  **Create codespace**
![Codespaces creation](/docs/images/codespaces_creation.png)
5.	Then it automatically start building container in the github codespaces ( wait for until container successfully created)
![Building container](/docs/images/codespaces_building_container.png)

 
## Working in a codespace in VS Code
GitHub Codespaces provides you with the full development experience of Visual Studio Code. You can edit code, debug, and use Git commands while developing in a codespace with VS Code.
>
>
![Codespaces in vscode](/docs/images/codespaces_vscode.png)

The main components of the user interface are:

>- **Side bar** - By default, this area shows your project files in the Explorer.
>- **Activity bar** - This displays the Views and provides you with a way to switch between them. You can reorder the Views by dragging and dropping them.
>- **Editor** - This is where you edit your files. You can right-click the tab for a file to access options such as locating the file in the Explorer.
>- **Panels** - This is where you can see output and debug information, as well as the default place for the integrated Terminal.
>- **Status bar** - This area provides you with useful information about your codespace and project. For example, the branch name, configured ports, and more.

## Navigating to an existing codespace
>- You can see every available codespace that you have created at github.com/codespaces.
>- Click the name of the codespace you want to develop in.


Alternatively, you can see any of your codespaces for a specific repository by navigating to that repository and selecting  Code. The dropdown menu will display all active codespaces for a repository.
