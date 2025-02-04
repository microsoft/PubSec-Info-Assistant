# Overview

* [Overview](#overview)
* [Getting started](#getting-started)
* [Additional considerations for deployment](#additional-considerations-for-secure-mode-deployment)
  * [Secure Communication to Azure](#secure-communication-to-azure)
  * [Deploying with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty)

## Overview

Information Assistant is for scenarios where infrastructure security and privacy are essential, like those in public sector and regulated industries. Key security features include:

* **Disabling public network access**: Restrict external access to safeguard public access.
* **Virtual network protection**: Deploy your Azure services within a secure virtual network.
* **Private endpoints**: The deployed Azure services connect exclusively through private endpoints within a virtual network where available.
* **Data encryption at rest and in transit**: Ensure encryption of data when stored and during transmission.

It is recommended you review the Information Assistant agent template [architecture](/docs/architecture.md) and determine your approach to establishing a [secure communication to Azure](#secure-communication-to-azure) as this is a prerequisite for the deployment.

Information Assistant can be deployed within a Sovereign Landing Zone. Read about [deploying with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty).

## Getting started


>IA is also compatible with the [Sovereign Landing Zone (SLZ)](https://aka.ms/slz) which is a [Microsoft Cloud for Sovereignty](https://www.microsoft.com/industry/sovereignty/cloud) offering. It is currently only compatible with the *Online* management group scope. See the [deploy with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty) section below for more details.

Once deployed only the Azure App Service named like, *infoasst-web-xxxxx*, will be accessible without a secure communication channel. You can share the URL of the website with users to start using the Information Assistant agent template.

## Additional considerations for deployment

### Secure communication to Azure

If your enterprise does not have an existing secure communication channel to the Azure cloud, consider setting up a Point-to-Site (P2S) Virtual Private Network (VPN) for deployment purposes only. To implement this for deployment purposes, you’ll need to add a virtual network and VPN Gateway to your Azure subscription by a VPN Gateway then downloading a VPN client and connecting it to the VPN Gateway to access resources on the virtual network (VNet). You will also need to then peer your virtual network where your VPN is to the Information Assistant virtual network.

For more information, see [using an Azure VPN Gateway Point-to-Site VPN](https://learn.microsoft.com/azure/vpn-gateway/work-remotely-support) and [create and manage a VPN Gateway using the Azure portal](https://learn.microsoft.com/azure/vpn-gateway/tutorial-create-gateway-portal).

**** Peering your network with the Information Assistant virtual network

When peering your virtual network with the Information Assistant virtual network, you will need to ensure the following settings are enabled on your peering configuration:

* Allow '*my VPN virtual network*' to access '*infoasst-vnet-xxxxx*'

* Allow '*my VPN virtual network*' to receive forwarded traffic from '*infoasst-vnet-xxxxx*'

* Allow gateway or route server in '*my VPN virtual network*' to forward traffic to '*infoasst-vnet-xxxxx*'

and the reciprocal setting of:

* Allow '*infoasst-vnet-xxxxx*' to access '*my VPN virtual network's*'

* Allow '*infoasst-vnet-xxxxx*' to receive forwarded traffic from '*my VPN virtual network's*'

* Enable '*infoasst-vnet-xxxxx*' to use '*my VPN virtual network's*' remote gateway or route server

This will ensure that the Azure DNS private resolver set up by the Information Assistant agent template can resolve traffic properly to your VPN connection.

### Deploying with Microsoft Cloud for Sovereignty

Sovereign use cases are best implemented based on [Sovereign Landing Zone (SLZ)](https://aka.ms/slz) which is a [Microsoft Cloud for Sovereignty](https://www.microsoft.com/industry/sovereignty/cloud) offering that provides opinionated infrastructure-as-code automation for deploying workloads. Microsoft Cloud for Sovereignty enables governments and public sector organizations to deploy workloads in Microsoft Cloud while helping meet their specific sovereignty, compliance, security, and policy requirements. Microsoft Cloud for Sovereignty creates software boundaries in the cloud to establish the extra protection that governments require, using cloud guardrails, policy, hardware-based confidentiality and encryption controls.

For a detailed overview of an SLZ and all its capabilities, see [Sovereign Landing Zone](https://github.com/Azure/sovereign-landing-zone) documentation on GitHub. Also, [review the sample reference architecture and guidance for deploying LLMs and Azure OpenAI in Retrieval Augmented Generation (RAG) pattern for implementations with the SLZ](https://learn.microsoft.com/industry/sovereignty/architecture/AIwithLLM/overview-ai-llm-configuration).


Information Assistant agent template is compatible with the *Online* management group scope. Within a SLZ deployment, you can find an established Connectivity management group where an existing virtual network and infrastructure already exist.

>We recommend that connectivity to Information Assistant in the *Online* management group be made accessible by peering the Information Assistant virtual network with the existing virtual network within the SLZ Connectivity management group.

At this time the current release of Information Assistant is not compatible with the default policies for the SLZ *Corp* (corporate) management group scope for the following reasons:

* Azure AI services currently do not support Azure Entra authentication when using Azure Private Links. This configuration violates one of the policy definitions in the SLZ *Corp* management group scope that prevent deployment.

* Web chat (private endpoints for Bing API services are not available)

Information Assistant is also compliant with the Azure Policy built-in [Sovereignty Baseline Global Policy Initiative](https://learn.microsoft.com/azure/governance/policy/samples/mcfs-baseline-global) to help enforce data residency requirements. This policy initiative is deployed with the SLZ, but can be assigned to your environment at the management group, subscription or resource group outside of an SLZ deployment.

Customers interested in operator transparency can also take advantage of [Transparency logs (preview)](https://learn.microsoft.com/industry/sovereignty/transparency-logs) by onboarding their tenant at no additional cost.

Learn more about how Cloud for Sovereignty can help enforce sovereignty concerns within the [product documentation](https://learn.microsoft.com/industry/sovereignty/) and by exploring the [getting started learning path](https://learn.microsoft.com/training/paths/get-started-sovereignty/).
