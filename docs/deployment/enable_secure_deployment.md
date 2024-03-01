# Enable Secure Deployment
 
## Overview

A secure Information Assistant deployment consists of a zero-trust compliant, private network and secures access to the application using Azure Front Door with a Web Application Firewall. All Information Assistant features and capabilities are available in a secure deployment. 

Securing the network is critically important. A secure deployment includes:

* Azure Virtual Network
* Subnets
* Configurable IP ranges
* Private DNS zones to support all services
* Private Link Scope for Azure Monitor
* Azure Front Door Premium with Web Application Firewall
* Private endpoints for all services
* Storage Accounts with four private endpoints for blob, file, queue, and table
* Private endpoints for each sub-resource - e.g. blob
* VNET integration for App Services and Functions for their outbound connections from the service to all private services
* Private link service between Azure Front Door and Front End Application Service

The following diagram shows a high-level view of the architecture.

[Secure deployment - High-level Architecture](../images/secure-deployment-high-level-architecture.png)

## Front end

The following diagram shows the end user's interaction with Information Assistant and the front end application's orchestration of the user's workflow. Azure Front door provides a public accessible SSL secured FQDN for the user to provide in their browser. The connection along with the user's Entra ID authentication are proxied through Azure Front Door to the Front end Application service. The Front end uses VNET integration to connect to the private network. Private DNS zones are used by the Front end application to connect with the appropriate service such as:

* Azure Storage Account, blob storage to upload files.
* Azure OpenAI to submit prompts.
* Azure AI search to discovery high-quality content from the explicitly uploaded files.
* Cosmos database to view the status of uploaded files.


[Secure Deploy - Front End Architecture](../images/secure-deployment-front-end-architecture.png)

### Document Extraction, Chunking, and Embedding

![Secure Deploy - Function App](../images/secure-deployment-function-app)

## How to Deploy

To enable a Secure deployment, you need to update the local.env file with the following value

1. Navigate to your `local.env` and set SECURE_MODE to true

   ```

   export SECURE_MODE=true


