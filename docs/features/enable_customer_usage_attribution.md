## Enable Customer Usage Attribution
Customer usage attribution is a feature that allows you to track the usage of Azure resources in customer subscriptions. This tracking capability helps partners track customer deployments. To enable customer usage attribution, you need to update the local.env file with the following values

1. Navigate to \`local.env\` and update:

   ```bash
   export ENABLE_CUSTOMER_USAGE_ATTRIBUTION=false
   export CUSTOMER_USAGE_ATTRIBUTION_ID=""
   ```

2. The `ENABLE_CUSTOMER_USAGE_ATTRIBUTION` parameter exists in the main bicep file. By default, it's set to `false`, disabling telemetry. To activate, set it to `true` and provide the GUID for `CUSTOMER_USAGE_ATTRIBUTION_ID`.

> **Note**:
>- Customer Usage Attribution is only for new deployments. It can't track already deployed resources.
>- Detailed information can be found [here](https://learn.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution).
