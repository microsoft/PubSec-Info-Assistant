# Information Assistant (IA) agent template - Estimation

The Azure pricing calculator helps estimate costs by considering the amount of data to be processed and stored, as well as the expected performance level. It allows users to customize and combine different Azure services for Information Assistant agent template, version 1.2, and provides cost estimates based on the chosen configurations.

| Solution            | Environment  |    Azure Pricing Calculator Link                                          |
| :------------------:|:-----------------------------:|:------------------------------------------------:|
| IA agent template, version 1.2 | Sandbox  |  [Sample Azure Estimation](https://azure.com/e/bd6e516bb0b549abb6d39cce088af684) |

## Azure Services

The following list of Azure Services will be deployed for IA agent template, version 1.2:

- App Service (App Service Plan) [:link:](https://azure.microsoft.com/en-ca/pricing/details/app-service/linux/)
- Application Insights [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Azure AI Services [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/)
- Azure Cosmos DB [:link:](https://azure.microsoft.com/en-ca/pricing/details/cosmos-db/autoscale-provisioned/)
- Bing Search Service [:link:](https://www.microsoft.com/en-us/bing/apis/llm-pricing)
- Container Registry [:link:](https://azure.microsoft.com/en-gb/pricing/details/container-registry)
- Azure AI Document Intelligence [:link:](https://azure.microsoft.com/en-ca/pricing/details/form-recognizer/#pricing)
- Azure Function (App Service Plan) [:link:](https://azure.microsoft.com/en-ca/pricing/details/functions/#pricing)
- Azure Key Vault [:link:](https://azure.microsoft.com/en-us/pricing/details/key-vault/)
- Log Analytics workspace [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Azure Logic App [:link:](https://azure.microsoft.com/en-us/pricing/details/logic-apps/)
- Azure AI Search [:link:](https://azure.microsoft.com/en-ca/pricing/details/search/#pricing)
- Azure OpenAI [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/openai-service/)
- Storage account  [:link:](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- Azure Active Directory [:link:](https://www.microsoft.com/en-sg/security/business/microsoft-entra-pricing?rtc=1)

---
**NOTE:**

- The proposed the cost estimation prepared based on Sandbox environment, estimation may vary customer to customer.
- For detailed Azure OpenAI Service please refer to the detailed [pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/#pricing)
- The estimation for Bing Search Service is not included in the Azure Estimation. Please consider it separately as mentioned under [Bing Search Service Pricing](https://www.microsoft.com/en-us/bing/apis/pricing)
- Customers with latency-sensitive scenarios can opt for provisioned throughput which allows customers to reserve model processing capacity. [Read More](/docs/deployment/considerations_production.md#gpt-model---throttling)

---

At this point this step is complete, please return to the [Deployment](../#deployment) step and continue.
