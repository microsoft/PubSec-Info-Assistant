# Information Assistant (IA) agent template Secure Mode - Estimation

The Azure pricing calculator helps estimate costs by considering the amount of data to be processed and stored, as well as the expected performance level. It allows users to customize and combine different Azure services for IA agent template secure mode and provides cost estimates based on the chosen configurations.

| Solution            | Mode | Environment  |    Azure Pricing Calculator Link  |
| :------------------:|:---------:|:---------------:|:-------------------:|
| IA agent template, version 1.2 | Secure | Sandbox  |  [Sample Azure Estimation](https://azure.com/e/192838582a644d02bd03bd07da650517) |

---

## Azure Services

The following list of Azure Services will be deployed for IA agent template secure mode:

- App Service (App Service Plan) [:link:](https://azure.microsoft.com/en-ca/pricing/details/app-service/linux/)
- Application Insights [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Azure AI Services [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/)
- Azure Cosmos DB [:link:](https://azure.microsoft.com/en-ca/pricing/details/cosmos-db/autoscale-provisioned/)
- Azure AI Document Intelligence [:link:](https://azure.microsoft.com/en-ca/pricing/details/form-recognizer/#pricing)
- Azure Function (App Service Plan) [:link:](https://azure.microsoft.com/en-ca/pricing/details/functions/#pricing)
- Azure Key Vault [:link:](https://azure.microsoft.com/en-us/pricing/details/key-vault/)
- Log Analytics workspace [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Azure AI Search [:link:](https://azure.microsoft.com/en-ca/pricing/details/search/#pricing)
- Azure OpenAI [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/openai-service/)
- Storage account [:link:](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- Azure Active Directory [:link:](https://www.microsoft.com/en-sg/security/business/microsoft-entra-pricing?rtc=1)
- Azure DDOS Standard Protection (recommended) [:link:](https://azure.microsoft.com/en-ca/pricing/details/ddos-protection/)
- Azure Container Registry [:link:](https://azure.microsoft.com/en-ca/pricing/details/container-registry/)
- Azure DNS Private Resolver [:link:](https://azure.microsoft.com/en-ca/pricing/details/dns/)
- Azure DNS Private Zones [:link:](https://azure.microsoft.com/en-us/pricing/details/dns/)
- Azure Private Link [:link:](https://azure.microsoft.com/en-ca/pricing/details/private-link/)
- Azure Private Endpoints [:link:](https://azure.microsoft.com/en-us/pricing/details/private-link/)
- Azure Container Registry [:link:](https://azure.microsoft.com/en-ca/pricing/details/container-registry/)
- Azure Network Interface [:link:](https://azure.microsoft.com/en-us/pricing/details/virtual-network/)
- Azure Network Security Group [:link:](https://azure.microsoft.com/en-us/pricing/details/virtual-network/)
- Azure Virtual Network [:link:](https://azure.microsoft.com/en-us/pricing/details/virtual-network/)

---

**NOTE:**

- The cost estimation provided is based on the Sandbox environment and may vary for different customers.
- For detailed pricing information on Azure OpenAI Service, please refer to [this link](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/#pricing).
- Customers with latency-sensitive scenarios can choose to use provisioned throughput, which allows them to reserve model processing capacity. For more information, please read [this document](/docs/deployment/considerations_production.md#gpt-model---throttling).
- Please note that the pricing of VPN Gateway and GitHub Codespaces is not covered as they are not part of the deployment.

---

At this point this step is complete, please return to the [Secure deployment][secureDeploymentRef] step and continue.

---

[secureDeploymentRef]: /docs/secure_deployment/secure_deployment.md
