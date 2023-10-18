# Developing in a GitHub Codespaces

* [Getting started with codespace](#getting-started-with-codespace)
* [Creating your codespace](#Creating-your-codespace)
  * From a GitHub template or any template repository to start a new project
  * From a branch in your repository for new feature work
  * From an open pull request to explore work-in-progress
* [Using GitHub Codespaces in Visual Studio Code](#Using-GitHub-Codespaces-in-Visual-Studio-Code)
  * [Prerequisites](#Prerequisites)
  * [Opening a codespace in VS Code](#Opening-a-codespace-in-VS-Code)
  * [Navigating to an existing codespace](#navigating-to-an-existing-codespace)
---
## Getting started with codespace

A codespace is a development environment that's hosted in the cloud. You can customize your project for GitHub Codespaces by committing configuration files to your repository, which creates a repeatable codespace configuration for all users of your project.

---
## Creating your codespace

1.	Click on    [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/microsoft/PubSec-Info-Assistant)
2.	New window will open where you can create a new codespace
3.	By default, you will be on **main** branch, you can switch to specific branch where you would like to create a codespace.
    Also it would provide option to select **Region**,**Machine type**
4. Then click on  **Create codespace**
![Codespaces creation](./docs/images/codespaces_creation.png)
5.	Then it automatically start building container in the github codespaces ( wait for until container successfully created)
![Building container](./docs/images/codespaces_building_container.png)
6. When you create a new codespace from a template, it is always opened in the Visual Studio Code web client. You can reopen an existing codespace in any supported editor
![Codespaces in vscode](./docs/images/codespaces_open_in_vs_code_desktop.png)

---
## Using GitHub Codespaces in Visual Studio Code

GitHub Codespaces provides you with the full development experience of Visual Studio Code. You can develop in your codespace directly in Visual Studio Code by connecting the GitHub Codespaces extension with your account on GitHub.

You can use your local install of Visual Studio Code to create, manage, work in, and delete codespaces. To use GitHub Codespaces in VS Code, you need to install the Codespaces extension. For more information on setting up GitHub Codespaces in VS Code, see "Prerequisites."

## Prerequisites

To develop in a codespace directly in VS Code, you must install and sign into the GitHub Codespaces extension with your GitHub credentials. The GitHub Codespaces extension requires VS Code October 2020 Release 1.51 or later.

Use the Visual Studio Code Marketplace to install the [GitHub Codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces) extension. For more information, see [Extension Marketplace](https://code.visualstudio.com./docs/editor/extension-gallery) in the VS Code documentation.


1. In VS Code, in the Activity Bar, click the Remote Explorer icon.
 ![Alt text](./docs/images/developing_in_a_codespaces_image_1.png)

    Note: If the Remote Explorer is not displayed in the Activity Bar:
    - Access the Command Palette. For example, by pressing Shift+Command+P (Mac) / Ctrl+Shift+P (Windows/Linux).
    - Type: details.
    - Click Codespaces: Details.

2. Select "GitHub Codespaces" from the dropdown at the top of the "Remote Explorer" side bar, if it is not already selected.

3. Click **Sign in to GitHub.**

    ![Alt text](./docs/images/developing_in_a_codespaces_image_2.png)

4. If you are not currently signed in to GitHub you'll be prompted to do so. Go ahead and sign in.

5. When you're prompted to specify what you want to authorize, click the **Authorize** button for "GitHub."

6. If the authorization page is displayed, click **Authorize Visual-Studio-Code.**

## Opening a codespace in VS Code

1. In VS Code, in the Activity Bar, click the Remote Explorer icon.

    ![Alt text](/docs/images/developing_in_a_codespaces_open_in_vscode_3.png)

2. Under "GitHub Codespaces", hover over the codespace you want to develop in.

3. Click the connection icon (a plug symbol).

    ![Alt text](/docs/images/developing_in_a_codespaces_open_in_vscode_4.png)


## Navigating to an existing codespace

- You can see every available codespace that you have created at github.com/codespaces.

    ![Alt text](./docs/images/developing_in_a_codespaces_open_in_vscode_2.png)

- Click the name of the codespace you want to develop in.
Alternatively, you can see any of your codespaces for a specific repository by navigating to that repository and selecting  Code. The dropdown menu will display all active codespaces for a repository.
