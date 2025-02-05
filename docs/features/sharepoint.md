# SharePoint File Ingestion

## Overview

A new logic app has been created to ingest SharePoint documents into a blob container for Information Assistant to process. It starts with the folder provided and crawls down through each folder in the SharePoint site. This process runs once every 24 hours.

### Restrictions

#### No RBAC
In order to access your files in SharePoint, you will have to login via Entra with the user that has access to these SharePoint files. We recommend creating a new user to do this.

#### Document Support
This ingestion process is only for **documents supported by our current pipeline**, the current officially supported file types can be found here [Features](./features.md#supported-document-types).  This ingestion process does **NOT** include lists or information found on pages in your SharePoint site. It is only for documents.


#### Files are Stored in Blob Storage
Your SharePoint files will be stored in the blob storage created by Information Assistant, they are not going directly into AI Search. **There will be a copy of all your SharePoint files you are ingesting in blob storage.**

### New Local Dev Variables

#### SHAREPOINT_TO_SYNC
This is a single quoted JSON Array of Objects within the env file. With the keys "url" and "folder" for each sharepoint site to ingest. You **MUST** update this in your environment if you have altered the existing config in your container and are redeploying. It will be overwritten upon redeployment with the value you've set in your environment.
The forward slash at the beginning of a folder is **required**
```JSON
export SHAREPOINT_TO_SYNC='[
    { "url": "https://yoursharepoint.com", "folder": "/Shared Documents"},
    { "url": "https://yoursharepoint.com", "folder": "/Shared Documents"}
    ]'
```

#### ENABLE_SHAREPOINT_CONNECTOR
This needs to be set to **true** if you want to use the SharePoint feature, otherwise the required resources for the SharePoint feature will not be deployed

## Usage Instructions

1. Fill in the SHAREPOINT_TO_SYNC variable in the env file, example can be found above
2. Deploy Information Assistant like normal
3. Once your deployment is complete, you'll need to login with a user that has access to the SharePoint sites you listed above. It is **strongly** recommended that you have created a new user for this purpose.
4. Go to your resource group in the [Azure Portal](https://portal.azure.com/), select the "sharepointonline" API Connection resource.
5. Click "Edit API Connection" in the menu on the left side of your screen.
6. Click "Authorize" and login with the user that has access to the SharePoint sites you put in your environment file. It is **strongly** recommended that you have created a new user for this purpose.
7. After you've done that **click Save**, if you do not click save, you will **NOT** be authorized.
8. Once you're authorized, you may manually run the logic app (see below) or wait 24 hours for it to automatically run.

## FAQ

**How do I manually run my logic app?**

*Go into your resource group, select infoasst-sharepointonline-XXXX and select "Run" in the Overview page*

**I want to update my SharePoint site or folder list, how do I do that?**

*Your configuration file is stored in the config blob storage container. You can edit these values at any time by editing the config.json file found there.*

**What happens if a file fails to be uploaded in the logic app?**

*The logic app moves onto the next file in the queue*

**I've deleted a file in SharePoint**

*The logic app looks for changes every time it runs. It will be deleted from the blob storage and Information Assistant on the next run*

**I've changed a file in SharePoint**

*The logic app looks for changes every time it runs. It will be updated from SharePoint on the next run.*

**Does this reupload the same files each time the process is run?**

*Only if the file has changed*
### How it works

![How does SharePoint Ingestion Work](/docs/images/sharepoint_logic_app_diagram.png)