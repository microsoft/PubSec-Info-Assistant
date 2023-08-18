# Customer Usage Attribution

Customer usage attribution associates usage from Azure resources in customer subscriptions created while deploying your IP with you as a partner. Forming these associations in internal Microsoft systems brings greater visibility to the Azure footprint running the Information Assistant Accelerator.

## Enable Customer Usage Attribution

To enable customer usage attribution, you need to update the local.env file with the following values

1. Navigate to your `local.env` and update:

   ```bash
   export ENABLE_CUSTOMER_USAGE_ATTRIBUTION=true
   export CUSTOMER_USAGE_ATTRIBUTION_ID="00000000-0000-0000-0000-000000000000"
   ```

2. Set **ENABLE_CUSTOMER_USAGE_ATTRIBUTION** parameter to `true` and provide your tracking GUID for **CUSTOMER_USAGE_ATTRIBUTION_ID**.

> **Note**:
>
>- Customer usage attribution is for new deployments and does not support tracking resources that have already been deployed.
>- Detailed information can be found [here](https://learn.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution).
