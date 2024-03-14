# User Experience

The end user leverages the web interface as the primary method to engage with the IA Accelerator, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined below.

## Having a conversation with your data

When you engage with IA Accelerator in the "Chat" method, the system maintains a history for your conversation and will be able to understand the context of your questions from one question to the next.

> You may activate the Chat engagement pattern by choosing the "Chat" link at the top of the page
> ![Chat Link](/docs/images/chat-interface.png)

## Analysis Panel

The Analysis Panel in the UX allows the user to explore three details about the answer to their question:

* Thought Process
* Supporting Content
* [Citations](/docs/features/ux_analysispanel.md#citations)

View the details of the [Analysis Panel](/docs/features/ux_analysispanel.md) feature or you can click on each section to get more specifics of that detail tab.

## Manage Content

When you engage with IA Accelerator in the "Manage Content" method, the system allows you to add new content and see the status of processing for content previously loaded into the IA Accelerator.

> You may activate the Manage Content engagement pattern by choosing the "Manage Content" link at the top of the page
> ![Manage Content Link](/docs/images/manage-content-interface.png)

### Uploading files

You can upload documents in the [supported formats listed above](/docs/features/features.md#document-pre-processing) through the user interface. To do so:

> 1. Click on the Manage Content link in the top of the interface
> ![Manage Content](/docs/images/manage-content-interface.png)
> 1. Then click on the "Upload files" tab.
> ![Upload Link](/docs/images/upload-files-link.png)
> 1. Select a folder, add some tags, and drag files to the user interface, or click the box to open a browse window
> ![Upload Link Drag and Drop](/docs/images/upload-files-drag-drop.jpg)

### View upload status

You can view the status up files that have been uploaded to the system through the user interface. To do so:

> 1. Click on the Manage Content link in the top of the interface
> ![Manage Content](/docs/images/manage-content-interface.png)
> 1. Then click on the "Upload Status" tab.
> ![Upload Status Link](/docs/images/view-upload-status-link.png)
> 1. At the top of the page you can filter your list of files by the folder they are in, the tags you applied during upload, or by the time frame of when they were uploaded from '4 hours' minimum to 'All' which will show all files. By clicking 'Refresh' after selecting your desired filters, the documents matching your criteria will be displayed. In the table of documents you can see the high level file state, a status detail message, the folder it is hosted in and the applied tags. If you wish to delete some files, select a file, multiple files or all files using the selection options on the left column of the table. Then click delete and confirm. You will then see a message in the bottom right of the screen indicating that this process can take up to 10 minutes, so refresh the screen and track progress.

> ![Upload Status Options and Refresh Links](/docs/images/view-upload-status-options-and-refresh.png)

### Using sample data - optional

Referring to the manage content sections above for [Upload files](/docs/images/upload-files-link.png) and [View upload status](/docs/images/view-upload-status-link.png), you can optionally load open source sample data to demonstrate the capabilities of the Information Assistant. The following data sources may be useful for your initial demonstration purposes:

> 1. Microsoft financial statements are available at the SEC Filings site. This dataset enables the user to ask questions such as "What are Microsoft sources of revenue?". You can optionally load Microsoft's [SEC Filings at gcs-web.com](https://microsoft.gcs-web.com/financial-information/sec-filings)
> 2. An Ice Cream data set is available at kaggle.com. This dataset enables the user to ask questions such ase "What are flavors of breyers?" You can optionally load the [Ice Cream Dataset from kaggle.com](https://www.kaggle.com/datasets/tysonpo/ice-cream-dataset)
>
> 3. Education Policy documents from US FERPA guidelines. This dataset enables the user to ask "How is strengthening student data privacy accomplished?". You can optionally load [US FERPA Policy documents](https://studentprivacy.ed.gov/node/548/)
