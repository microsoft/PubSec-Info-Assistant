# Information Assistant (IA) agent template - Estimation

The Azure pricing calculator helps estimate costs by considering the amount of data to be processed and stored, as well as the expected performance level. It allows users to customize and combine different Azure services for Information Assistant agent template and provides cost estimates based on the chosen configurations.

| Solution            | Environment  |    Azure Pricing Calculator Link                                          |
| :------------------:|:-----------------------------:|:------------------------------------------------:|
| IA agent template, version 2.0 | Sandbox  |  [Sample Azure Estimation](https://azure.com/e/9172d010c7d244cabf6fcb6d1b586121) |

## Azure Services

The following list of Azure services will be deployed for IA agent template:

- App Service (App Service Plan) [:link:](https://azure.microsoft.com/pricing/details/app-service/linux/)
- Application Insights [:link:](https://azure.microsoft.com/pricing/details/monitor/)
- Log Analytics workspace [:link:](https://azure.microsoft.com/pricing/details/monitor/)
- Azure AI services [:link:](https://azure.microsoft.com/pricing/details/cognitive-services/)
- Azure AI Document Intelligence [:link:](https://azure.microsoft.com/pricing/details/form-recognizer/#pricing)
- Azure AI Search [:link:](https://azure.microsoft.com/pricing/details/search/#pricing)
- Azure OpenAI Service [:link:](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- Azure Key Vault [:link:](https://azure.microsoft.com/pricing/details/key-vault/)
- Storage account [:link:](https://learn.microsoft.com/azure/storage/common/storage-account-overview)
- Microsoft Bing Search APIs [:link:](https://www.microsoft.com/en-us/bing/apis/llm-pricing)
- Microsoft Entra [:link:](https://www.microsoft.com/security/business/microsoft-entra-pricing?rtc=1)
- Azure DDoS Standard Protection [:link:](https://azure.microsoft.com/pricing/details/ddos-protection/)
- Azure DNS Resolver [:link:](https://azure.microsoft.com/pricing/details/dns/)
- Azure Virtual Network [:link:](https://azure.microsoft.com/pricing/details/virtual-network/)
- Azure Network Interface [:link:](https://azure.microsoft.com/pricing/details/virtual-network/)
- Azure Network Security Group [:link:](https://azure.microsoft.com/pricing/details/virtual-network/)
- Azure Private Link [:link:](https://azure.microsoft.com/pricing/details/private-link/)
- Azure Private DNS Zone [:link:](https://azure.microsoft.com/pricing/details/private-link/)
- Azure Private Endpoints [:link:](https://azure.microsoft.com/pricing/details/private-link/)


---
**NOTE:**

- The cost estimation prepared is based on the Sandbox environment and may vary by customer.
- For detailed pricing information on Azure OpenAI Service, please refer to [this link](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/#pricing).
- Customers with latency-sensitive scenarios can opt for provisioned throughput which allows customers to reserve model processing capacity. For more information, please read [this document](/docs/deployment/considerations_production.md#gpt-model---throttling).
- The estimation for Bing Search Service is not included in this estimate. Please consider it separately as mentioned under [Bing Search API pricing](https://www.microsoft.com/bing/apis/pricing).
- Please note that the pricing of VPN Gateway and GitHub Codespaces is not covered as they are not part of the deployment.

---

At this point this step is complete, please return to the [Deployment](/docs/deployment/deployment.md) step and continue.
