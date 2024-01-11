# IA Accelerator, version 1.0 - Estimation

The Azure pricing calculator helps estimate costs by considering the amount of data to be processed and stored, as well as the expected performance level. It allows users to customize and combine different Azure services for IA Accelerator, version 0.4 delta, and provides cost estimates based on the chosen configurations.


| Solution            | Environment  |    Azure Pricing Calculator Link                                          |
| :------------------:|:-----------------------------:|:------------------------------------------------:|
| IA Accelerator, version 1.0 | Sandbox  |  [Sample Azure Estimation](https://azure.com/e/9849721efce04059be9ed8d5735a7a58) | 

---
### Azure Services

The following list of Azure Services will be deployed for IA Accelerator, version 0.4 delta:

- App Service [:link:](https://azure.microsoft.com/en-ca/pricing/details/app-service/linux/)
- Azure Function(App Service plan) [:link:](https://azure.microsoft.com/en-ca/pricing/details/functions/#pricing)
- Application Insights [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Azure Cosmos DB [:link:](https://azure.microsoft.com/en-ca/pricing/details/cosmos-db/autoscale-provisioned/)
- Azure AI Document Intelligence [:link:](https://azure.microsoft.com/en-ca/pricing/details/form-recognizer/#pricing)
- Azure OpenAI [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/openai-service/)
- Azure AI Services [:link:](https://azure.microsoft.com/en-ca/pricing/details/cognitive-services/)
- Azure AI Search [:link:](https://azure.microsoft.com/en-ca/pricing/details/search/#pricing)
- Azure Active Directory [:link:](https://www.microsoft.com/en-sg/security/business/microsoft-entra-pricing?rtc=1)
- Azure AI Video Indexer [:link:](https://azure.microsoft.com/en-us/pricing/details/video-indexer/)
- Log Analytics workspace [:link:](https://azure.microsoft.com/en-ca/pricing/details/monitor/)
- Storage account  [:link:](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)

---
**NOTE:**

- The proposed the cost estimation prepared based on Sandbox environment, estimation may vary customer to customer.
- For detailed Azure OpenAI Service [pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/#pricing)
- Customers with latency-sensitive scenarios can expect predictable performance, provisioned throughput allows customers to reserve model processing capacity. [Read More](/docs/deployment/considerations_production.md#gpt-model---throttling)

---

At this point this step is complete, please return to the [Deployment](../#deployment) step and continue.
