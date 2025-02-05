# Customer Usage Attribution

Customer usage attribution associates usage from Azure resources in customer subscriptions created while deploying your IP with you as a partner. Forming these associations in internal Microsoft systems brings greater visibility to the Azure footprint running the Information Assistant agent template.

## Enable Customer Usage Attribution

To enable customer usage attribution, you need to update these azd variables

1. Set **USE_CUSTOMER_USAGE_ATTRIBUTION** parameter to `true` and provide your tracking GUID for **CUSTOMER_USAGE_ATTRIBUTION_ID**.

   ```bash
   azd env set USE_CUSTOMER_USAGE_ATTRIBUTION true
   azd env set CUSTOMER_USAGE_ATTRIBUTION_ID "{CUA GUID}"
   ```

> **Note**:
>
>- Customer usage attribution is for new deployments and does not support tracking resources that have already been deployed.
>- Detailed information can be found [here](https://learn.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution).
