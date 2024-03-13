# Sharepoint File Ingestion

## Overview

A new logic app has been created to ingest sharepoint documents into a blob container for Information Assistant to process. It starts with the folder provided and crawls down through each folder in the sharepoint site. This process runs once every 24 hours.

### Restrictions

#### No RBAC
In order to access your files in Sharepoint, you will have to login via Entra with the user that has access to these sharepoint files. We recommend creating a new user to do this.

#### Document Support
This ingestion process is only for **documents supported by our current pipeline**, the current officially supported file types can be found here [Features](./features.md#supported-document-types).  This ingestion process does **NOT** include lists or information found on pages in your sharepoint site. It is only for documents.

#### Files are Stored in Blob Storage
Your sharepoint files will be stored in the blob storage created by Information Assistant, they are not going directly into AI Search. **There will be a copy of all your sharepoint files you are ingesting in blob storage.**

### New Local Dev Variables

#### Sharepoint Sites

This is a comma delimited list of sharepoint site(s) you wish to ingest. **It shares a one-to-one relationship with the sharepoint folders variable.** If you have one sharepoint site, you need one sharepoint folder and vice versa. You may list the same site twice if you wish to more granular control over what is being crawled in sharepoint.

#### Sharepoint Folders

This is a comma delimited list of sharepoint folder(s) you wish to be your entry point for the ingestion. **It shares a one-to-one relationship with the sharepoint sites variable.** If you have one sharepoint folder, you need one sharepoint site and vice versa. It will crawl this folder and then automatically crawl any folders beneath it. The sharepoint site root is typically /Shared Documents

## Usage Instructions

1. Fill in the sharepoint_sites, sharepoint_folders variables in your environment file. An example of that might look like this

`export SHAREPOINT_SITES="https://wwpubsec.sharepoint.com/sites/SharepointTest, https://wwpubsec.sharepoint.com/sites/SharepointTest"`

`export SHAREPOINT_FOLDERS="/Shared Documents/Example1, /Shared Documents/Example2"`

Notice the 1:1 relationship between the sites and folders. Each site has **ONLY ONE** folder.

2. Deploy Information Assistant like normal
3. Once your deployment is complete, you'll need to login with a user that has access to the sharepoint sites you listed above. It is **strongly** recommended that you have created a new user for this purpose.
4. Go to your resource group in the [Azure Portal](https://portal.azure.com/), select the "sharepointonline" API Connection resource.
5. Click "Edit API Connection" in the menu on the left side of your screen.
6. Click "Authorize" and login with the user that has access to the sharepoint sites you put in your environment file. It is **strongly** recommended that you have created a new user for this purpose.
7. After you've done that **click Save**, if you do not click save, you will **NOT** be authorized.
8. Once you're authorized, you may manually run the logic app (see below) or wait 24 hours for it to automatically run.

## FAQ

**How do I manually run my logic app?**

*Go into your resource group, select infoasst-sharepointonline-XXXX and select "Run" in the Overview page*

**I want to update my sharepoint site or folder list, how do I do that?**

*Your configuration file is stored in the config blob storage container. You can edit these values at any time by editing the config.json file found there.*

**What happens if a file fails to be uploaded in the logic app?**

*The logic app moves onto the next file in the queue*

**I've deleted a file in sharepoint**

*The logic app looks for changes every time it runs. It will be deleted from the blob storage and Information Assistant on the next run*

**I've changed a file in sharepoint**

*The logic app looks for changes every time it runs. It will be updated from sharepoint on the next run.*

**Does this reupload the same files each time the process is run?**

*Only if the file has changed*
### How it works

![How does Sharepoint Ingestion Work](/docs/images/sharepoint_logic_app_diagram.png)