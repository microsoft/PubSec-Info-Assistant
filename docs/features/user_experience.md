# User Experience

The end user leverages the web interface as the primary method to engage with the IA Accelerator, and the Azure OpenAI service. The user interface is very similar to that of the OpenAI ChatGPT interface, though it provides different and additional functionality which is outlined below.

## Having a conversation with your data

When you use the "Chat" capabilities, the system maintains a history for your conversation and will be able to understand the context of your questions from one question to the next in a conversation flow. History is at the session level and not persisted. When your session goes away, so does your conversational history.

> Activate the Chat engagement pattern by choosing the "Chat" link at the top right side of the page

> ![Chat Link](/docs/images/info-assist-chat-ui.png)

There are new modes that extend the Information Assistant user experience. Similar to COPILOT, Information Assistant has a Work and a Web Mode called Work Only and Work + Web respectfully. There is also a Generative mode enabling user interaction with the LLM without grounding the response in their data.

## Work Only

Work Only mode provides the natural language conversation with your data that you are familiar with from previous versions of Information Assistant. In this mode, the user is limited to interacting with their private data they upload into the Information Assistant. The color scheme for Work Only mode is intentionally the same as M365 Copilot.

## Work + Web

The Work + Web mode experience starts similar to Work Only mode. It provides new options in the response enabling the user to __Searh Web__ to see if there is newer information available or __Compare with Web__ to compare the response from their data with information available on the web. In this mode the user can choose to ask questions and have the grounding data be either sourced from private data they upload or web search results from the Bing Search service. The default grounding mode can be changed in the Adjust settings located on the top right just below the Assistants preview links.

![Chat Link](/docs/images/work-plus-web-ui.png)

Selecting the __Search Web__ or __Compare with Web__ options changes the user experience as follows:

### Search Web

Selecting __Search Web__ from a Work Only response asks the same question on the web. The UI color scheme changes to reflect the user is searching a different source.

![Chat Link](/docs/images/work-plus-web-search-web.png)

Options in the __Search Web__ response include __Search Work__ and __Compare with Work__.

The __Search Work__ option in the Web response works similar to the __Search Web__ option found in the Work Only response. When using the __Work + Web__ mode users can choose to ground in either Work or the Web by default. Default grounding can be changed in the Adjust settings located on the top right just below the Assistants preview links.

![Chat Link](/docs/images/adjust-settings-ui.png)
![Chat Link](/docs/images/configure-answer-generation.png)



### Compare with Web

Selecting __Compare with Web__ from a Work Only response asks the same question on the web then compares your data response with the response from the web. The UI color scheme changes to reflect the user is comparing Work with Web

![Chat Link](/docs/images/work-plus-web-compare-with-web.png)


With different grounding settings in the __Work + Web__ mode, the compare option can be Work compared to Web or Web compared to Work.

![Chat Link](/docs/images/work-plus-web-compare-with-work.png)

The __Compare__ response includes both work and web citations. Selecting a citation activates the analysis panel.


## Analysis Panel

The Analysis Panel in the UX allows the user to explore the details about the answer to their question:

* Thought Process
* Supporting Content
* [Citations](/docs/features/ux_analysispanel.md#citations)

View the details of the [Analysis Panel](/docs/features/ux_analysispanel.md) feature or you can click on each section to get more specifics of that detail tab.



## Generative

Generative mode enables user interaction with the LLM without grounding the response in their data.

![Chat Link](/docs/images/generative-ungrounded-ui.png)

On the top right are two new preview features called Math Assistant and Tabular Data Assistant. The Math Assistant and Tabular Data assistant are being released in preview mode as we continue to evaluate and mitigate the potential risks associated with autonomous reasoning Agents, such as misuse of external tools, lack of transparency, biased outputs, privacy concerns, and remote code execution vulnerabilities. With future release we plan work to enhance the safety and robustness of these autonomous reasoning capabilities.

## Math Assistant

The Math Assistant combines natural language understanding with robust mathematical reasoning, enabling users to express mathematical queries in plain language and receive step-by-step solutions and insights.

![Chat Link](/docs/images/math-assistant-ui.png)

Users can select an example query or enter their own math question. There are three options below the question prompt where the user can ask for clues, ask the assistant to show them how to solve the math problem, or simply provide an answer.

### Give me clues

Give me clues will assist the user without answering the math question or providing step by step instructions to solve the problem.

![Chat Link](/docs/images/math-assistant-give-me-clues.png)

### Show me how to Solve it

Show me how to Solve it presents the user with ordered steps they can perform to answer the math question.

![Chat Link](/docs/images/math-assistant-show-me-how-to-solve.png)

### Show Me the Answer

Show Me the Answer works like a calculator and simply provides the answer to the math question.

![Chat Link](/docs/images/math-assistant-show-me-the-answer.png)

## Tabular Data Assistant

The Tabular Data Assistants allows users to ask natural language questions about tabular data in CSV files and extract insights from structured datasets with the ability to filter, aggregate, and perform computations on CSV data.

First, the user must upload a CSV file. They can drag and drop the file onto the Tabular Data Assistant UI or browse their file system(s) to select files then click the Upload File button.

![Chat Link](/docs/images/tab-data-assist-upload-files-ui.png)

Once a file has been uploaded the user can select an example query or enter thier own question about content in the CSV file.

![Chat Link](/docs/images/tab-data-assist-how-many.png)

## Manage Content

When you engage with IA Accelerator in the "Manage Content" method, the system allows you to add new content and see the status of processing for content previously loaded into the IA Accelerator.

> You may activate the Manage Content engagement pattern by choosing the "Manage Content" link at the top of the page
> ![Manage Content Link](/docs/images/manage-content-ui.png)

### Uploading files

You can upload documents in the [supported formats](/docs/features/features.md#document-pre-processing) through the user interface. To do so:

> 1. Click on the Manage Content link in the top of the interface
> 1. Then click on the "Upload files" tab.
> ![Upload Link](/docs/images/manage-content-upload-files.png)
> 1. Select a folder, add some tags, and drag files to the user interface, or click the box to open a browse window, select file(s) then click the __Upload Files__ button.

> ![Upload Files Link](/docs/images/manage-content-upload-files-1.png)

### View upload status

You can view the status of files that have been uploaded to the system through the user interface. To do so:

> 1. Click on the Manage Content link in the top of the interface
> ![Manage Content](/docs/images/manage-content-ui.png)
> 1. Then click on the "Upload Status" tab.
> ![Upload Status Link](/docs/images/manage-content-upload-status.png)
> 1. At the top of the page you can filter your list of files by the folder they are in, the tags you applied during upload, or by the time frame of when they were uploaded from '4 hours' minimum to 'All' which will show all files. By clicking 'Refresh' after selecting your desired filters, the documents matching your criteria will be displayed. In the table of documents you can see the high level file state, a status detail message, the folder it is hosted in and the applied tags. 

### Delete Content

Users can delete documents through the same Manage Content UI they use to review the status of files they have uploaded. If you wish to delete some files, select a file, multiple files or all files using the selection options on the left column of the table. Then click delete and confirm. You will then see a message in the bottom right of the screen indicating that this process can take up to 10 minutes, so refresh the screen and track progress. Follow the steps outlined below to delete files:

1. __Access the Manage Content UI__: Select the __Manage Content__ tab located at the top right.
2. __Filter Your Files__: On the left, select __Upload Status__ then use the dropdown lists to apply any desired filters.
3. __Refresh the List__: Click the __Refresh__ icon to update the list of files based on your filters.
4. __Delete a File__: Once the filtered list appears, select the file you want to delete. Then, click the __Delete__ link located to the right of the Refresh link.

> ![Upload Status Options and Refresh Links](/docs/images/manage-content-delete.png)


### Using sample data - optional

Referring to the manage content sections above for [Upload files](/docs/images/upload-files-link.png) and [View upload status](/docs/images/view-upload-status-link.png), you can optionally load open source sample data to demonstrate the capabilities of the Information Assistant. The following data sources may be useful for your initial demonstration purposes:

> 1. Microsoft financial statements are available at the SEC Filings site. This dataset enables the user to ask questions such as "What are Microsoft sources of revenue?". You can optionally load Microsoft's [SEC Filings at gcs-web.com](https://microsoft.gcs-web.com/financial-information/sec-filings)
> 2. An Ice Cream data set is available at kaggle.com. This dataset enables the user to ask questions such ase "What are flavors of breyers?" You can optionally load the [Ice Cream Dataset from kaggle.com](https://www.kaggle.com/datasets/tysonpo/ice-cream-dataset)
>
> 3. Education Policy documents from US FERPA guidelines. This dataset enables the user to ask "How is strengthening student data privacy accomplished?". You can optionally load [US FERPA Policy documents](https://studentprivacy.ed.gov/node/548/)
