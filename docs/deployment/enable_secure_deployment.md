# Enable Secure Deployment
 
## Overview

A secure Information Assistant deployment should be enabled for production environments and should be considered for government clients or any client requiring additional levels of security. A secure deployment includes:

* Azure Virtual Network
* Subnets
* Configurable IP ranges
* Private DNS zones
* Private Endpoints
* Private Link Scope for Azure Monitor
* Storage Accounts with private endpoints for each sub-resource: blob, file, queue, and table
* VNET integration for App Services and Functions 

## Azure OpenAI service

The secure deployment option for Information Assistant is not supported when using an existing Azure OpenAI service instance in your subscription. Do not enable the secure deployment option if you have set USE_EXISTING_AOAI to "true" in your local.env file.

The following diagram shows a high-level view of the architecture.

[Secure deployment - High-level Architecture](../images/secure-deployment-high-level-architecture.png)

The Information Assistant secure deployment option assumes that clients have established secure communications from their enterprise to the Azure cloud that will enable users to access Information Assistant capabilities. The secure communication mechanism is represented in this high level architecture diagram with ExpressRoute although there are other options for securely communicating with Azure.

A more detailed architecuture diagram is available: 

[Secure deployment - Detailed Architecture](../images/secure-deployment-detailed-architecture.png)

## Front end

The following diagram shows the end user's interaction with Information Assistant and the Information Assistant's front end application's orchestration of the user's workflow. The Front end uses VNET integration to connect to the private network. Private DNS zones are then used by the Front end application to connect with the appropriate service such as:

* Azure Storage Account, blob storage to upload files
* Azure OpenAI to submit prompts
* Azure AI search to discovery content from uploaded files
* Cosmos database to view the status of uploaded files


[Secure Deploy - Front End Architecture](../images/secure-deployment-front-end-architecture.png)


## How to Enable a Secure Deployment

To enable a Secure Deployment, update your local.env file as described below:

1. Navigate to your `local.env` and set SECURE_MODE to true

   ```

   export SECURE_MODE=true


