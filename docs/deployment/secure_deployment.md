# Secure Deployment

> [!IMPORTANT]  
> The Information Assistant "**secure mode**" option assumes clients have or will establish secure communications from their enterprise to the Azure cloud that will enable users to access its capabilities. In addition there are other key considerations:
>
>Secure mode is not compatible with the following IA features:
>
> * Using an existing Azure OpenAI Services
> * Web chat (secure endpoints for Bing API services are not yet available)
> * SharePoint connector (secure endpoints for Azure Logic Apps and SharePoint connector for Logic Apps are not yet available)
> * Multimedia (secure endpoints for Azure Video Indexer services are not yet available)
>
>Secure mode requires a DDOS Protection Plan for Virtual Network Protection. There is a limit of 1 DDOS protection plan for a subscription in a region. You can reuse an existing DDOS plan in your tenant or Info Assistant can deploy one for you.
>

* [Overview](#overview)
* [Architecture](#architecture)
  * [High Level Architecture](#high-level-architecture)
  * [Detailed Architecture](#detailed-architecture)
* [Front End Architecture](#front-end-architecture)
* [Back End Service Architecture](#back-end-service-architecture)
* [Private vnet and endpoint Architecture](#private-vnet-and-endpoint-architecture)
* [How to Deploy Secure Mode](#how-to-deploy-secure-mode)
* [Additional Considerations for Secure Deployment](#additional-considerations-for-secure-deployment)
  * [Network and subnet CIDR configuration](#network-and-subnet-cidr-configuration)
  * [Secure Communication to Azure](#secure-communication-to-azure)
  * [Secure Communication with Microsoft Cloud for Sovereignty (MCfSov)](#secure-communication-with-microsoft-cloud-for-sovereignty-mcfsov)
  
## Overview

Information Assistant secure mode is essential when heightened levels of security are necessary. Secure mode is recommended for all production systems. Key features of secure mode include:

* __Disabling Public Network Access__: Restrict external access to safeguard sensitive data.
* __Virtual Network Protection__: Shield your system within a secure virtual network.
* __Data Encryption at Rest and in Transit__: Ensure confidentiality by encrypting data when stored and during transmission.
* __Integration via Private Endpoints__: All Azure services connect exclusively through private endpoints within a virtual network

The secure mode adds several new Azure resources and will likely require additional Azure permissions. New resources will include:

* Azure Monitor
* Virtual Network (VNet)
* Subnets
* Network Security Groups (NSGs)
* Private DNS Zones
* Private Endpoints
* Private Links
* DNS Private Resolver

## Architecture

Secure mode builds on the Single Virtual Network Pattern in which all components of your workload are inside a single virtual network (VNet). This pattern is possible if you're operating in a single region, as a virtual network can't span multiple regions. The virtual network isolates your resources and traffic from other VNets and provides a boundary for applying security policies. Services deployed within the same virtual network communicate securely. This additional level of isolation helps prevent unauthorized external access to services and helps protect your data.

### High Level Architecture

![Secure mode - High level architecture](../images/secure-deploy-high-level-architecture.png)

The secure communication mechanism is represented in this high level architecture diagram with ExpressRoute although there are other options for securely communicating with Azure. Azure ExpressRoute helps protect data during communication.

### Detailed Architecture

The detailed architecture diagram below shows the VNet is subdivided into subnets that further segment network resources. This allows more granular control of network traffic and security rules. These subnets contain Private Endpoints, network interfaces that connect privately and securely to Azure Services. By using a Private IP address from your VNet, a Private Endpoint enables secure communications with Azure Services from your VNet, reducing exposure to the public internet. This improves network security through:

1. Network isolation: VNets and Subnets provide a segregated environment where only authorized resources can communicate with each other.
2. Reduced Attack Surface: Private Endpoints ensure that Azure services are accessed via the private IP space of your VNet, not over the public network, which significantly reduces the risk of external attacks.
3. Granular Access Control: Network Security Groups (NSGs) can be associated with VNets, subnets and network interfaces to filter network traffic to and from resources within a VNet. This allows for fine-tuned control over access and security policies.

Deploying a dedicated Azure service into your virtual network provides the following capabilities:

* Resources within the virtual network can communicate with each other privately, through private IP addresses.
* On-premises resources can access resources in a virtual network using private IP addresses over a Site-to-Site VPN (VPN Gateway) or ExpressRoute.
* Virtual networks can be peered to enable resources in the virtual networks to communicate with each other, using private IP addresses.
* The Azure service fully manages service instances in a virtual network. This management includes monitoring the health of the resources and scaling with load.
* Private endpoints allow ingress of traffic from your virtual network to an Azure resource securely.

The Information Assistant deploys to a resource group within a subscription in your tenant. The deployment requires a secure communication channel to complete successfully, as illustrated by the ExpressRoute or S2S VPN for user access to the Virtual Network (vNet) on the left of the diagram below.

![Secure mode - Detailed Architecture](../images/secure-deploy-detail-architecture.png)

## Front End Architecture

The user experience is provided by a front-end application deployed as an App Service and associated with an App Service Plan. When the front-end application needs to securely communicate with resources in the VNet, the outbound calls from the front-end application are enabled through VNet integration ensuring that traffic is sent over the private network where private DNS zones resolve names to private VNet IP addresses. The diagram below shows user's securely connecting to the VNet to interact with the Information Assistant user experience (UX) in the App Subnet.

The front-end application uses VNet integration to connect to the private network and private DNS zones to access the appropriate services such as:

* __Azure Storage Account (Blob Storage)__: Used for file uploads.
* __Azure OpenAI__: Enables prompt submissions.
* __Azure AI Search__: Facilitates content discovery from uploaded files.
* __Cosmos DB__: Provides visibility into the status of uploaded files.

![Secure mode - Front End Architecture](../images/secure-deploy-frontend-architecture.png)

## Back End Service Architecture

Back-end processing handles uploading your private data, performs document extraction and enrichment leveraging AI Services as illustrated in the following diagram:

![Secure mode - Function Architecture](../images/secure-deploy-function-architecture.png)

### Private vnet and endpoint Architecture

The network architecture diagram below contains additional details on Private Endpoints and Private Links. A Private Link provides access to services over the Private Endpoint network interface. Private Endpoint uses a private IP address from your virtual network. You can access various services over that private IP address such as:

* Azure PaaS services like Azure OpenAI and Azure AI Search
* Customer-owned services that Azure hosts
* Partner services that Azure hosts

Traffic between your virtual network and the service that you're accessing travels across the Azure network backbone. As a result, you no longer access the service over a public endpoint, effectively reducing exposure and enhancing security.

![Secure mode - Network Architecture](../images/secure-deploy-network-architecture.png)

## How to Deploy Secure Mode

To perform a secure deployment, follow these steps:

1. Open your forked repository in VSCode.
2. Navigate to the `scripts/environments/local.env` file
3. Update the following settings:

   ```bash
   export SECURE_MODE=true
   export ENABLE_WEB_CHAT=false
   export USE_EXISTING_AOAI=false
   export ENABLE_SHAREPOINT_CONNECTOR=false
   export ENABLE_MULTIMEDIA=false
   ```

   *Note: Secure mode is blocked when using an existing Azure OpenAI service. We have blocked this scenario to prevent updating a shared instance of Azure OpenAI that may be in use by other workloads*

4. Review the network and subnet CIDRs for  your deployment. See the section [Network and subnet CIDR configuration](#network-and-subnet-cidr-configuration) for more details.
5. Decide you approach for DDOS protection for your Info Assistant vnet. If you plan to use an existing DDOS protection plan you can select it in one of two ways:
   * **RECOMMENDED:** You can manually provide the DDOS plan ID in your `local.env` file using the following parameter. Be sure to update the subscription id, resource group name, and ddos plan name values.

       ```bash
       export DDOS_PLAN_ID="/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/ddosProtectionPlans/{ddos plan name}"`
       ```

   * You can let the deployment choose a DDOS protection plan at deployment time. If you do not provide the parameter above, the deployment scripts will prompt you with a choice to use the first found existing DDOS plan in your subscription or Info Assistant will create one automatically.
   ***IMPORTANT: The script can only detect DDOS protection plans in the same Azure subscription you are logged into***

      The prompt will appear like the following when running `make deploy`:

      ```bash
      Found existing DDOS Protection Plan: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/infoasst-xxxxxxx/providers/Microsoft.Network/ddosProtectionPlans/my_ddos_plan
      Do you want to use this existing DDOS Protection Plan (y/n)? 
      ```

      Or if no DDOS plan is found in the subscription the script will simply ouput

      ```bash
      No existing DDOS protection plan found. Terraform will create a new one.
      ```

6. Now you can resume the normal [Deployment](/docs/deployment/deployment.md) configuration and start `make deploy`. When you encounter the connectivity prompt come back here and resume at Step 7.
7. Determine your plan for network connectivity to the Info Assistant vnet. This is required to complete the deployment. When you run `make deploy` it will now stop after the infrastructure is deployed and provide the following prompt:

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

    Here are the three types of connectivity we have tested and validated for Information Assistant secure mode:

    * Establish vnet peering with your corporate network via Express Route.
    * Establish a Point-to-Site (P2S) VPN for your development workstation. See [Secure Communication to Azure](#secure-communication-to-azure) section.
    * If using Microsoft's Cloud for Sovereignty (MCfSov), there are additional considerations you can find in the [Secure Communication with Microsoft Cloud for Sovereignty (MCfSov)](#secure-communication-with-microsoft-cloud-for-sovereignty-mcfsov) section.

8. If you are choosing to use a P2S VPN to connect to the Info Assistant vnet, then follow these steps. Otherwise, skip to Step 18.

    [!IMPORTANT] *You will need your VPN configuration and client certificate that matches your Azure VPN Gateway to continue*
9. Copy your `vpnconfig.ovpn` and PFX certificate file into the `/workspace/openvpn` folder in the Codespace.
10. Extract the private key and the base64 thumbprint from the .pfx. There are multiple ways to do this. Using OpenSSL on your computer is one way.

    `openssl pkcs12 -in "filename.pfx" -nodes -out "profileinfo.txt"`

    The profileinfo.txt file will contain the private key and the thumbprint for the CA, and the Client certificate. Be sure to use the thumbprint of the client certificate.
11. Open profileinfo.txt in a text editor. To get the thumbprint of the client (child) certificate, select the text including and between "-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----" for the child certificate and copy it. You can identify the child certificate by looking at the subject=/ line.
12. Open the vpnconfig.ovpn file and find the section shown below. Replace everything between "cert" and "/cert".

    ```text
    # P2S client certificate
    # please fill this field with a PEM formatted cert
    <cert>
    $CLIENTCERTIFICATE
    </cert>
    ```

13. Open the profileinfo.txt in a text editor. To get the private key, select the text including and between "-----BEGIN PRIVATE KEY-----" and "-----END PRIVATE KEY-----" and copy it.
14. Open the vpnconfig.ovpn file in a text editor and find this section. Paste the private key replacing everything between "key" and "/key".

    ```text
    # P2S client root certificate private key
    # please fill this field with a PEM formatted key
    <key>
    $PRIVATEKEY
    </key>
    ```

15. Don't change any other fields. Save the VPN config file.
16. Next run the following commands to enable the tunnel on the Codespace

    ```bash
    sudo mkdir -p /dev/net
    sudo mknod /dev/net/tun c 10 200
    sudo chmod 600 /dev/net/tun
    ```

17. Use the filled in configuration in client input to connect to the VPN.

    * To connect using the command line, type the following command:

      `sudo openvpn --config <name and path of your VPN profile file>`

    * To disconnect using command line, type the following command:

      `sudo pkill openvpn`

      The bash prompt should block when connected. You will need to open another bash Terminal in VSCode to run additional commands. If the bash prompt does not block but return you can run the following command to review the logs for errors:

      `sudo cat openvpn.log`

18. Once connected you will need to add the DNS Private Resolver IP address to your Codespace configuration. The DNS Private Resolver IP was output to your VSCode Terminal for you in the prompt to confirm connectivity. Do this by running the following command:

    `sudo nano /etc/resolv.conf`

    Add the following entry in your `resolv.conf` file:

    ```text
    nameserver XXX.XXX.XXX.XXX
    ```

19. You should now be able to verify you can resolve the private IP of the Information Assistant. `nslookup` is installed in the Codespace for this use.

## Additional Considerations for Secure Deployment

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
export TF_VAR_azure_video_indexer_CIDR="10.0.8.104/29"
export TF_VAR_bing_service_CIDR="10.0.8.112/29"
export TF_VAR_azure_openAI_CIDR="10.0.8.120/29"
export TF_VAR_integration_CIDR="10.0.8.192/26"
export TF_VAR_acr_CIDR="10.0.8.128/29"
export TF_VAR_dns_CIDR="10.0.8.136/29"
```

*NOTE: The following subnets require a minimum size:*

* *azure monitor (ampls) requires at least a /27 range*
* *storage account requires at least a /28 range*
* *integration requires at least a /26 range*
* *dns requires at least a /28 range*

### Secure Communication to Azure

If your enterprise does not have an existing secure communication channel to the Azure cloud, consider setting up a Point-to-Site (P2S) Virtual Private Network (VPN) for demonstration purposes only. This will allow you to access the Information Assistant user experience (UX). To implement this for demonstration purposes, you’ll need to add a VPN Gateway to the Information Assistant infrastructure by creating a gateway subnet and a VPN Gateway then downloading a VPN client and connecting it to the VPN Gateway to access resources on the virtual network (vNet).

More information on [using an Azure VPN Gateway Point-to-Site VPN](https://learn.microsoft.com/en-us/azure/vpn-gateway/work-remotely-support)

Detailed information on how to [create and manage a VPN Gateway is available at learn.microsoft.com](https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-create-gateway-portal)

### Secure Communication with Microsoft Cloud for Sovereignty (MCfSov)

TBD