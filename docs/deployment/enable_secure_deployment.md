# Enable Secure Deployment
 
## Overview

A secure Information Assistant deployment includes:

* Azure Virtual Network
* Subnets
* Configurable IP ranges
* Private DNS zones to support all services
* Private Endpoints for all services
* Private Link Scope for Azure Monitor
* Storage Accounts with private endpoints for each sub-resource: blob, file, queue, and table
* VNET integration for App Services and Functions 

The following diagram shows a high-level view of the architecture.

[Secure deployment - High-level Architecture](../images/secure-deployment-high-level-architecture.png)

## Front end

The following diagram shows the end user's interaction with Information Assistant and the front end application's orchestration of the user's workflow. The Front end uses VNET integration to connect to the private network. Private DNS zones are used by the Front end application to connect with the appropriate service such as:

* Azure Storage Account, blob storage to upload files.
* Azure OpenAI to submit prompts.
* Azure AI search to discovery high-quality content from the explicitly uploaded files.
* Cosmos database to view the status of uploaded files.


[Secure Deploy - Front End Architecture](../images/secure-deployment-front-end-architecture.png)


## How to Deploy

To enable a Secure Deployment, update your local.env file as described below:

1. Navigate to your `local.env` and set SECURE_MODE to true

   ```

   export SECURE_MODE=true


