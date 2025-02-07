# Secure mode deployment

* [Getting started](#getting-started)
* [Additional Azure account requirements](#additional-azure-account-requirements)
* [Overview](#overview)
* [Architecture](#architecture)
  * [High level architecture](#high-level-architecture)
  * [Detailed architecture](#detailed-architecture)
* [Front end architecture](#front-end-architecture)
* [Back end service architecture](#back-end-service-architecture)
* [Private virtual network and endpoint architecture](#private-virtual-network-and-endpoint-architecture)
* [Sizing estimator](#sizing-estimator)
* [How to deploy secure mode](#how-to-deploy-secure-mode)
* [Additional considerations for secure mode deployment](#additional-considerations-for-secure-mode-deployment)
  * [Network and subnet CIDR configuration](#network-and-subnet-cidr-configuration)
  * [Secure Communication to Azure](#secure-communication-to-azure)
  * [Deploying with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty)

## Getting started

It is recommended that you start with a [standard deployment](/docs/deployment/deployment.md) of Information Assistant (IA) to become familiar with the deployment process before starting the secure mode deployment. The documentation provided below builds upon the standard deployment and assumes you are familiar with the deployment process.

### Prerequisites

Before you get started ensure you go through the following prerquisites: 
 
1. The Information Assistant **secure mode** option requires all the [parameters and configuration of a standard deployment](/docs/deployment/deployment.md#configure-env-files). 

2. **Secure communication channel to Azure cloud**: assumes clients have or will establish secure communications from their enterprise to the Azure cloud that will enable it to be deployed (e.g., Azure ExpressRoute, Azure VPN Gateway). If your enterprise does not have an existing secure communication channel to the Azure cloud, consider setting up a Point-to-Site (P2S) Virtual Private Network (VPN) for deployment purposes. See [Secure Communication to Azure](#secure-communication-to-azure) section below for more details.
Note that establishing a secure communication is required to complete the deployment steps below. 

3. (Optional) If you are planning to deploy Information Assistant **secure mode** with [Microsoft Cloud for Sovereignty](https://www.microsoft.com/industry/sovereignty/cloud), you have to first set up and deploy a [Sovereign Landing Zone (SLZ)](https://aka.ms/slz). 
Note that Information Assistant *secure mode* is currently only compatible with the *Online* management group scope. See the [deploy with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty) section below for more details.

[!IMPORTANT] 
>Secure mode is not compatible with the following IA features:
>
> * Using an existing Azure OpenAI services
> * Web chat (private endpoints for Bing API services are not available)
> * SharePoint connector (private endpoints for Azure Logic Apps and SharePoint connector for Logic Apps are not yet available)
>
>It is recommended to use secure mode with a DDoS Protection Plan for Virtual Network Protection, but it is not required. There is a limit of 1 DDoS protection plan for a subscription in a region. You can reuse an existing DDoS plan in your tenant, Information Assistant can deploy one for you, or you can choose to not use a DDoS Protection Plan on your virtual network.
>


## Additional Azure account requirements

In order to deploy the secure mode of Information Assistant, you will need the following in addition to the standard [Azure account requirements](/README.md#azure-account-requirements):

* **Azure account permissions**:
  * If you are going to use an existing DDoS that resides in another subscription, you will need to have `Microsoft.Network/ddosProtectionPlans/join/action` permission on the subscription where the DDoS Protection Plan exists to allow associating to the virtual network when it is created. This permission can be provided with the [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/networking#network-contributor) role.

## Overview

Information Assistant secure mode is for scenarios where infrastructure security and privacy are essential, like those in public sector and regulated industries. Key features of secure mode include:

* **Disabling public network access**: Restrict external access to safeguard public access.
* **Virtual network protection**: Deploy your Azure services within a secure virtual network.
* **Private endpoints**: The deployed Azure services connect exclusively through private endpoints within a virtual network where available.
* **Data encryption at rest and in transit**: Ensure encryption of data when stored and during transmission.

Secure mode adds several new Azure resources and will likely require additional Azure permissions. New resources will include:

* Azure Monitor
* Virtual Network (VNet)
* Subnets
* Network Security Groups (NSGs)
* Private DNS Zones
* Private Endpoints
* Private Links
* DNS Private Resolver
* DDoS Protection Plan (optional configuration)

## Architecture

Secure mode builds on the [Single Virtual Network Pattern](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/network-level-segmentation#pattern-1-single-virtual-network) in which all components of your workload are inside a single virtual network (VNet). This pattern is only possible if you're operating in a single region, as a virtual network can't span multiple regions. The virtual network isolates your resources and traffic from other VNets and provides a boundary for applying security policies. Services deployed within the same virtual network communicate securely. This additional level of isolation helps prevent unauthorized external access to services and helps protect your data.

Additionally, secure mode isolates each Azure Service type into subnets to allow further protection to be applied via Network Security Groups (NSGs) if you want to extend the provided configuration.

### High level architecture

![Secure mode - High level architecture](../images/secure-deploy-high-level-architecture.png)

The secure communication mechanism is represented in this high level architecture diagram with ExpressRoute although there are other options for securely communicating with Azure. Azure ExpressRoute helps protect data during communication. In this example, an organizations enterprise networking configuration can be peered with the virtual network deployed by Information Assistant secure mode to allow users access to the application.

### Detailed architecture

The detailed architecture diagram below shows the VNet is subdivided into subnets that further segment network resources. This allows more granular control of network traffic and security rules. These subnets contain private endpoints, network interfaces that connect privately and securely to Azure services. By using a private IP address from your VNet, a private endpoint enables secure communications with Azure services from your VNet, reducing exposure to the public internet. This improves network security through:

1. Network isolation: VNets and Subnets provide a segregated environment where only authorized resources can communicate with each other.
2. Reduced Attack Surface: Private endpoints ensure that Azure services are accessed via the private IP space of your VNet, not over the public network, which significantly reduces the risk of external attacks.
3. Granular Access Control: Network Security Groups (NSGs) can be associated with VNets, subnets and network interfaces to filter network traffic to and from resources within a VNet. This allows for fine-tuned control over access and security policies.

Deploying a dedicated Azure service into your virtual network provides the following capabilities:

* Resources within the virtual network can communicate with each other privately, through private IP addresses.
* On-premises resources can access resources in a virtual network using private IP addresses over a VPN Gateway or ExpressRoute.
* Virtual networks can be peered to enable resources in the virtual networks to communicate with each other, using private IP addresses.
* The Azure service fully manages service instances in a virtual network. This management includes monitoring the health of the resources and scaling with load.
* Private endpoints allow ingress of traffic from your virtual network to an Azure resource securely.

The Information Assistant deploys to a resource group within a subscription in your tenant. The deployment requires a secure communication channel to complete successfully, as illustrated by the ExpressRoute or VPN Gateway for user access to the enterprise virtual Network on the left of the diagram below that is peered with the Information Assistants virtual network.

![Secure mode - Detailed Architecture](../images/secure-deploy-detail-architecture.png)

## Front end architecture

The user experience is provided by a front-end application deployed as an App Service and associated with an App Service Plan. When the front-end application needs to securely communicate with resources in the VNet, the outbound calls from the front-end application are enabled through VNet integration ensuring that traffic is sent over the private network where private DNS zones resolve names to private VNet IP addresses. The diagram below shows user's securely connecting to the VNet to interact with the Information Assistant user experience (UX) from a network peered with the Information Assistant virtual network.

The front-end application uses VNet integration to connect to the private network and private DNS zones to access the appropriate services such as:

* **Azure Storage Account (Blob Storage)**: Used for file uploads.
* **Azure OpenAI**: Enables prompt submissions.
* **Azure AI Search**: Facilitates content discovery from uploaded files.
* **Cosmos DB**: Provides visibility into the status of uploaded files.
* **Azure Container Registry**: Where the Azure App Service pulls its source image from to host the application.

![Secure mode - Front End Architecture](../images/secure-deploy-frontend-architecture.png)

## Back end service architecture

Back-end processing handles processing of your private data, performs document extraction and enrichment leveraging Azure AI services, and performs embedding and indexing leveraging Azure OpenAI and Azure AI Search. All public network access to the back-end processing system is disallowed including the Azure Portal. Data can be loaded into the secured process in two ways:

* Through the Information Assistant Content Management UX feature
* Data can be added to the Azure Storage Account from a device that is on a virtual network peered to the Information Assistant virtual network

All of the services in the back-end are integrated through private endpoints ensuring that traffic is sent over the private network where private DNS zones resolve names to private VNet IP addresses as illustrated in the following diagram:

![Secure mode - Function Architecture](../images/secure-deploy-function-architecture.png)

### Private virtual network and endpoint architecture

The tables below contain additional details on private endpoints and Private Links. A Private Link provides access to services over the private endpoint network interface. Private endpoint uses a private IP address from your virtual network. Traffic between your virtual network and the service that you're accessing travels across the Azure network backbone. As a result, you no longer access the service over a public endpoint, effectively reducing exposure and enhancing security.

#### Information Assistant virtual network configuration for Azure Commercial

Information Assistant Virtual Network CIDR: x.x.x0/24

Subnet | CIDR | Private Links | Azure Service
---|---|---|---
ampls | x.x.x.0/27 | privatelink.azure-automation.net<br/>privatelink.monitor.azure.com<br/>privatelink.ods.opinsights.azure.com<br/>privatelink.oms.opinsights.azure.com | Azure Log Analytics<br/>Azure Application Insights<br/>Azure Monitor
storageAccount | x.x.x.32/28 | privatelink.blob.core.windows.net<br/>privatelink.file.core.windows.net<br/>privatelink.queue.core.windows.net<br/>privatelink.table.core.windows.net | Azure Storage Account
cosmosDb | x.x.x.48/29 | privatelink.documents.azure.com | Azure CosmosDb
azureAi | x.x.x.56/29 | privatelink.cognitiveservices.azure.com | Azure AI multi-service account<br/>Azure Document Intelligence
keyVault | x.x.x.72/29 | privatelink.vaultcore.azure.net | Azure Key Vault
app | x.x.x.64/29 | privatelink.azurewebsites.net | Azure App Service
function | x.x.x.80/29 | privatelink.azurewebsites.net | Azure Function App
enrichment | x.x.x.88/29 | privatelink.azurewebsites.net | Azure App Service
integration | x.x.x.192/26 | N/A | Azure App Service<br/>Azure Function App
aiSearch | x.x.x.96/29 | privatelink.search.windows.net | Azure AI Search
azureOpenAi | x.x.x.120/29 | privatelink.openai.azure.com | Azure Open AI
acr | x.x.x.128/29 | privatelink.azurecr.io | Azure Container Registry
dns | x.x.x.176/28 | N/A | Azure DNS Private Resolver

#### Information Assistant virtual network configuration for Azure USGovernment

Information Assistant Virtual Network CIDR: x.x.x0/24

Subnet | CIDR | Private Links | Azure Service
---|---|---|---
ampls | x.x.x.0/27 | privatelink.azure-automation.us<br/>privatelink.monitor.azure.us<br/>privatelink.ods.opinsights.azure.us<br/>privatelink.oms.opinsights.azure.us | Azure Log Analytics<br/>Azure Application Insights<br/>Azure Monitor
storageAccount | x.x.x.32/28 | privatelink.blob.core.usgovcloudapi.net<br/>privatelink.file.core.usgovcloudapi.net<br/>privatelink.queue.core.usgovcloudapi.net<br/>privatelink.table.core.usgovcloudapi.net | Azure Storage Account
cosmosDb | x.x.x.48/29 | privatelink.documents.azure.us | Azure CosmosDb
azureAi | x.x.x.56/29 | privatelink.cognitiveservices.azure.us | Azure AI multi-service account<br/>Azure Document Intelligence
keyVault | x.x.x.72/29 | privatelink.vaultcore.usgovcloudapi.net | Azure Key Vault
app | x.x.x.64/29 | privatelink.azurewebsites.us | Azure App Service
function | x.x.x.80/29 | privatelink.azurewebsites.us | Azure Function App
enrichment | x.x.x.88/29 | privatelink.azurewebsites.us | Azure App Service
integration | x.x.x.192/26 | N/A | Azure App Service<br/>Azure Function App
aiSearch | x.x.x.96/29 | privatelink.search.azure.us | Azure AI Search
azureOpenAi | x.x.x.120/29 | privatelink.openai.azure.us | Azure Open AI
acr | x.x.x.128/29 | privatelink.azurecr.us | Azure Container Registry
dns | x.x.x.176/28 | N/A | Azure DNS Private Resolver

See [Virtual network and subnet CIDRs](#network-and-subnet-cidr-configuration) section for customizing the values for your network.

## Sizing estimator

The IA agent template secure mode needs to be sized appropriately based on your use case. Please review our [sizing estimator](/docs/secure_deployment/secure_costestimator.md) to help find the configuration that fits your needs.

To change the size of components deployed, make changes in the [Terraform Variables](/infra/variables.tf) file.

Once you have completed the sizing estimator and sized your deployment appropriately, please move on to the How to deploy secure mode step.

## How to deploy secure mode

To perform a secure mode deployment, follow these steps:

1. Open your forked repository in VSCode.
2. Navigate to the `scripts/environments/local.env` file
3. Ensure you have configured all the [standard parameters](/docs/deployment/deployment.md#configure-env-files)
4. Update the following additional settings:

   ```bash
   export SECURE_MODE=true
   export ENABLE_WEB_CHAT=false
   export USE_EXISTING_AOAI=false
   export ENABLE_SHAREPOINT_CONNECTOR=false
   ```

   *Note: Secure mode is blocked when using an existing Azure OpenAI service. We have blocked this scenario to prevent updating a shared instance of Azure OpenAI that may be in use by other workloads.*

5. Review the network and subnet CIDRs for your deployment. See the section [Network and subnet CIDR configuration](#network-and-subnet-cidr-configuration) for more details.
6. Decide your approach for DDoS protection for your Information Assistant virtual network. If you simply don't want to use a DDoS protection plan simply leave the `ENABLE_DDOS_PROTECTION_PLAN` flag set to false. If you plan to use a DDoS protection plan, you need to enable it by setting the `ENABLE_DDOS_PROTECTION_PLAN` flag set to true and then you can select a specific DDoS protection plan in one of two ways:
   * **RECOMMENDED:** You can manually provide the DDoS plan ID in your `local.env` file using the following parameter. Be sure to update the subscription id, resource group name, and DDoS plan name values.

       ```bash
       export ENABLE_DDOS_PROTECTION_PLAN=true
       export DDOS_PLAN_ID="/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/ddosProtectionPlans/{ddos plan name}"
       ```

   * You can let the deployment choose a DDoS protection plan at deployment time. If you do not provide the parameter above, the deployment scripts will prompt you with a choice to use the first found existing DDoS plan in your subscription or Information Assistant will create one automatically.
   ***IMPORTANT: The script can only detect DDoS protection plans in the same Azure subscription you are logged into.***

      The prompt will appear like the following when running `make deploy`:

      ```bash
      Found existing DDOS Protection Plan: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/infoasst-xxxxxxx/providers/Microsoft.Network/ddosProtectionPlans/my_ddos_plan
      Do you want to use this existing DDOS Protection Plan (y/n)? 
      ```

      Or if no DDoS plan is found in the subscription the script will simply ouput:

      ```bash
      No existing DDOS protection plan found. Terraform will create a new one.
      ```

7. Determine your plan for network connectivity to the Information Assistant virtual network. This is required to complete the deployment. When you run `make deploy` it will now stop after the infrastructure is deployed and provide the following prompt:

    ```text
      ____ _               _    
    / ___| |__   ___  ___| | __
    | |   | '_ \ / _ \/ __| |/ /
    | |___| | | |  __/ (__|   < 
    \____|_| |_|\___|\___|_|\_\
                                
      ____                            _   _       _ _         
    / ___|___  _ __  _ __   ___  ___| |_(_)_   _(_) |_ _   _ 
    | |   / _ \| '_ \| '_ \ / _ \/ __| __| \ \ / / | __| | | |
    | |__| (_) | | | | | | |  __/ (__| |_| |\ V /| | |_| |_| |
    \____\___/|_| |_|_| |_|\___|\___|\__|_| \_/ |_|\__|\__, |
                                                        |___/ 
    Connection from the client machine to the Information Assistant virtual network is required to continue the deployment.
    Please configure your connectivity and ensure you are using the DNS resolver at XXX.XXX.XXX.XXX

    Are you ready to continue (y/n)? 
    ```

    Here are the three types of connectivity we recommend for Information Assistant secure mode:

    * Establish virtual network peering with your corporate network to the Information Assistant virtual network, and private access via ExpressRoute.
    * Establish a Point-to-Site (P2S) VPN Gateway for your development workstation. See [Secure Communication to Azure](#secure-communication-to-azure) section.
    * If using Microsoft's Cloud for Sovereignty, there are additional considerations you can find in the [Deploying with Microsoft Cloud for Sovereignty](#deploying-with-microsoft-cloud-for-sovereignty) section.

8. If you are choosing to use a P2S VPN to connect to the Information Assistant virtual network, then follow steps 9 - 15 for the initial configuration. Otherwise, skip to Step 16.

    :warning: *You will need your VPN configuration and client certificate that matches your Azure VPN Gateway to continue*

9. Copy your `vpnconfig.ovpn` and PFX certificate file into the `/workspace/openvpn` folder in the GitHub Codespace.
10. Extract the private key and the base64 thumbprint from the .pfx. There are multiple ways to do this. Using OpenSSL on your computer is one way.

    `openssl pkcs12 -in "filename.pfx" -nodes -out "profileinfo.txt"`

    The profileinfo.txt file will contain the private key and the thumbprint for the CA, and the Client certificate. Be sure to use the thumbprint of the client certificate.
11. Open `profileinfo.txt` in a text editor. To get the thumbprint of the client (child) certificate, select the text including and between "-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----" for the child certificate and copy it. You can identify the child certificate by looking at the subject=/ line.
12. Open the `vpnconfig.ovpn` file and find the section shown below. Replace everything between "cert" and "/cert".

    ```text
    # P2S client certificate
    # please fill this field with a PEM formatted cert
    <cert>
    $CLIENTCERTIFICATE
    </cert>
    ```

13. Open the profileinfo.txt in a text editor. To get the private key, select the text including and between "-----BEGIN PRIVATE KEY-----" and "-----END PRIVATE KEY-----" and copy it.
14. Open the `vpnconfig.ovpn` file in a text editor and find this section. Paste the private key replacing everything between "key" and "/key".

    ```text
    # P2S client root certificate private key
    # please fill this field with a PEM formatted key
    <key>
    $PRIVATEKEY
    </key>
    ```

15. Don't change any other fields. Save the VPN config file.

16. Now perform the rest of the normal [Deployment](/docs/deployment/deployment.md) configuration and start `make deploy`. When you encounter the connectivity prompt come back here and resume at Step 17. Note: You must repeat steps 17 - 22 each time your Codespace stops during a deployment.
17. Once the deployment stops to prompt you for connectivity you will need to add the DNS Private Resolver IP address to your GitHub Codespace configuration. The DNS Private Resolver IP was output to your VSCode Terminal for you in the prompt to confirm connectivity. Do this by running the following command:

    `sudo nano /etc/resolv.conf`

    Add the following entry at the top in your `resolv.conf` file:

    ```text
    nameserver XXX.XXX.XXX.XXX
    ```
    Note: make sure the nameserver entry is at the top of the file. 
18. Save the `/etc/resolv.conf` file.
19. Now run the following commands to enable the tunnel on the Codespace

    ```bash
    sudo mkdir -p /dev/net
    sudo mknod /dev/net/tun c 10 200
    sudo chmod 600 /dev/net/tun
    ```
20. Connect to the VPN using the filled in VPN configuration file. Open a second bash prompt in VSCode and use the following commands:

    * To connect using the command line, type the following command:

      `sudo openvpn --config <name and path of your VPN profile file>`

    * To disconnect using command line, type the following command:

      `sudo pkill openvpn`

      The bash prompt should block when connected. You will need to open another bash Terminal in VSCode to run additional commands. If the bash prompt does not block but return you can run the following command to review the logs for errors:

      `sudo cat openvpn.log`

21. You should now be able to verify you can resolve the private IP of the Information Assistant. `nslookup` is installed in the Codespace for this use.
22. Now answer `y` to the connectivity prompt and let the deployment complete. If your deployment has stopped, you can simply run `make deploy` again to get back to the connectivity prompt.

Once deployed only the Azure App Service named like, *infoasst-web-xxxxx*, will be accessible without the VPN established. You can share the URL of the website with users to start using the Information Assistant agent template.

## Additional considerations for secure mode deployment

### Network and subnet CIDR configuration

Secure mode creates a virtual network and multiple subnets, improving network isolation and data protection. Internet Protocol (IP) addresses and the corresponding Classes Inter-Domain Routing (CIDR)s are available as Terraform parameters. To avoid any IP address conflicts with your existing network(s), update the virtual network IP Addresses or CIDRs, then copy this block of variables into your `scripts/environments/local.env` file (*values shown are default values*)

```bash
export TF_VAR_virtual_network_CIDR="10.0.8.0/24"
export TF_VAR_azure_monitor_CIDR="10.0.8.0/27"
export TF_VAR_storage_account_CIDR="10.0.8.32/28"
export TF_VAR_cosmos_db_CIDR="10.0.8.48/29"
export TF_VAR_azure_ai_CIDR="10.0.8.56/29"
export TF_VAR_webapp_CIDR="10.0.8.64/29"
export TF_VAR_key_vault_CIDR="10.0.8.72/29"
export TF_VAR_functions_CIDR="10.0.8.80/29"
export TF_VAR_enrichment_app_CIDR="10.0.8.88/29"
export TF_VAR_search_service_CIDR="10.0.8.96/29"
export TF_VAR_bing_service_CIDR="10.0.8.112/29"
export TF_VAR_azure_openAI_CIDR="10.0.8.120/29"
export TF_VAR_integration_CIDR="10.0.8.192/26"
export TF_VAR_acr_CIDR="10.0.8.128/29"
export TF_VAR_dns_CIDR="10.0.8.176/28"
```

*NOTE: The following subnets require a minimum size:*

* *azure monitor (ampls) requires at least a /27 range*
* *storage account requires at least a /28 range*
* *integration requires at least a /26 range*
* *dns requires at least a /28 range*

### Secure communication to Azure

If your enterprise does not have an existing secure communication channel to the Azure cloud, consider setting up a Point-to-Site (P2S) Virtual Private Network (VPN) for deployment purposes only. To implement this for deployment purposes, you’ll need to add a virtual network and VPN Gateway to your Azure subscription by a VPN Gateway then downloading a VPN client and connecting it to the VPN Gateway to access resources on the virtual network (VNet). You will also need to then peer your virtual network where your VPN is to the Information Assistant virtual network.

For more information, see [using an Azure VPN Gateway Point-to-Site VPN](https://learn.microsoft.com/en-us/azure/vpn-gateway/work-remotely-support) and [create and manage a VPN Gateway using the Azure portal](https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal).

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

The [Sovereign Landing Zone (SLZ)](https://aka.ms/slz) is a [Microsoft Cloud for Sovereignty](https://www.microsoft.com/industry/sovereignty/cloud) offering that provides opinionated infrastructure-as-code automation for deploying workloads. Microsoft Cloud for Sovereignty enables governments and public sector organizations to deploy workloads in Microsoft Cloud while helping meet their specific sovereignty, compliance, security, and policy requirements. Microsoft Cloud for Sovereignty creates software boundaries in the cloud to establish the extra protection that governments require, using cloud guardrails, policy, hardware-based confidentiality and encryption controls.

For a detailed overview of an SLZ and all its capabilities, see [Sovereign Landing Zone](https://github.com/Azure/sovereign-landing-zone) documentation on GitHub. Also, [review the sample reference architecutre and guidance for deploying LLMs and Azure OpenAI in Retrieval Augmented Generation (RAG) pattern for implementations with the SLZ](https://learn.microsoft.com/industry/sovereignty/architecture/AIwithLLM/overview-ai-llm-configuration).


Information Assistant agent template is compatible with the *Online* management group scope. Within a SLZ deployment, you can find an established Connectivity management group where an existing virtual network and infrastructure already exist.

>We recommend that connectivity to Information Assistant in the *Online* management group be made accessible by peering the Information Assistant virtual network with the existing virtual network within the SLZ Connectivity management group.

At this time the current release of Information Assistant is not compatible with the default policies for the SLZ *Corp* (corporate) management group scope for the following reasons:

* Azure Functions require use of an Azure Storage Account to store function keys and state files for scalable Azure Function Plans. Currently we are unable to use both Azure Entra authentication and Azure Private Links for Azure Storage together with Azure Function Apps. This configuration violates one of the policy definitions in the SLZ *Corp* management group scope that prevent deployment.
* Azure AI services currently do not support Azure Entra authentication when using Azure Private Links. This configuration violates one of the policy definitions in the SLZ *Corp* management group scope that prevent deployment.

Secure mode is also compliant with the Azure Policy built-in [Sovereignty Baseline Global Policy Initiative](https://learn.microsoft.com/en-us/azure/governance/policy/samples/mcfs-baseline-global) to help enforce data residency requirements. This policy initiative is deployed with the SLZ, but can be assigned to your environment at the management group, subscription or resource group outside of an SLZ deployment.

Customers interested in operator transparency can also take advantage of [Transparency logs (preview)](https://learn.microsoft.com/industry/sovereignty/transparency-logs) by onboarding their tenant at no additional cost.

Learn more about how Cloud for Sovereignty can help enforce sovereignty concerns within the [product documentation](https://learn.microsoft.com/industry/sovereignty/) and by exploring the [getting started learning path](https://learn.microsoft.com/training/paths/get-started-sovereignty/).
