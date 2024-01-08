# Debugging the Enrichment Web App Locally in VSCode

Embeddings processing is performed in an Azure App Service. The system uses this functionality to perform enrichments, create embeddings, and index documents when messages arrive in the **embeddings-queue** queue. At some point you may wish to step through this code line by line in VS Code. Prior to debugging, ensure you stop the webapp in the Azure portal, or it will pick up and test messages you deliver to the embeddings queue before your code can read the message.

To start debugging firstly add breakpoints to the code and then simply select the Run & Debug menu option in the left bar, or Ctrl+Shift+D. Next select `Python: Enrichment Webapp`  and hit the play button. This will then initiate the code and stop on your first breakpoint.

One tip is to save a copy of a message in the embeddings queue which triggers your logic. Then you will be able to just resubmit this message again and again to initiate and trace your code.

![Attach to function](/docs/images/fastapi_debug.png)