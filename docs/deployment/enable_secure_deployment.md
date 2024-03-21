# Enable Secure Deployment

## Overview

A secure Information Assistant deployment should be enabled for production environments and should be considered for government clients or any client requiring additional levels of security. A secure deployment includes:

* Azure Virtual Network
* Subnets
* Configurable IP ranges
* Private DNS zones
* Private Endpoints
* Private Link Scope for Azure Monitor
* Storage Accounts with private endpoints for each sub-resource
* VNET integration for App Services and Functions

## Architecture

The following diagram shows a high-level view of the architecture.

[Secure deployment - High-level Architecture](../images/secure-deployment-high-level-architecture.png)

The Information Assistant secure deployment option assumes clients have established secure communications from their enterprise to the Azure cloud that will enable users to access Information Assistant capabilities. The secure communication mechanism is represented in this high level architecture diagram with ExpressRoute although there are other options for securely communicating with Azure.

A more detailed architecuture diagram is available:

[Secure deployment - Detailed Architecture](../images/secure-deployment-detailed-architecture.png)

If you do not have a secure communication channel between your enterprise and the Azure cloud you could establish a Point to Site (P2S) Virtual Private Network (VPN) to enable access to the Information Assistant for demonstration purposes. This approach would require a VPN Gateway be added to the Information Assistant deployment.

More information on [using an Azure VPN Gateway Point-to-Site VPN](https://learn.microsoft.com/en-us/azure/vpn-gateway/work-remotely-support)

Detailed information on how to [create and manage a VPN Gateway is available at learn.microsoft.com](https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal)

After setting up a VPN Gateway, [configure the Azure VPN Client on your local machine](https://learn.microsoft.com/en-us/azure/vpn-gateway/openvpn-azure-ad-client)

### Secure deployment - Architecture recommendation

For scenarios beyond a simple demonstration consider [Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/)

## Front end

The following diagram shows the end user's interaction with Information Assistant and the Information Assistant's front-end application's orchestration of the user's workflow. The front-end uses VNET integration to connect to the private network. Private DNS zones are used by the front-end application to connect with the appropriate services such as:

* Azure Storage Account, blob storage to upload files
* Azure OpenAI to submit prompts
* Azure AI Search to discovery content from uploaded files
* Cosmos database to view the status of uploaded files

[Secure Deploy - Front End Architecture](../images/secure-deployment-front-end-architecture.png)

## How to Enable a Secure Deployment

To enable a Secure Deployment, update your local.env file as described below:

1. Navigate to your `local.env` and set SECURE_MODE to true

```text
   export SECURE_MODE=true
```

## Additional Considerations for Secure Deployment

The secure deployment option for Information Assistant is not supported when using an existing Azure OpenAI service instance in your subscription. Do not enable the secure deployment option if you have set USE_EXISTING_AOAI to "true" in your local.env file.

The secure deployment defines vNet and subnet IP Addresses along with the corresponding CIDR. Check the vNet IP Address range and CIDR in the network module of the main.tf file in the infra folder and update the vNet or subnet IP Addresses or CIDR to avoid conflicts with your existing network(s).
