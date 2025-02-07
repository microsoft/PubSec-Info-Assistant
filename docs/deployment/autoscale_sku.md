# Autoscale settings documentation

These are the current out of the box Autoscale settings.
You may find better settings to fit your needs. This document explains how this can be accomplished.

## App Service Plan Autoscale for Web App

### Overview

The App Service Plan Autoscale settings for the web app are defined in the file located at `/infra/core/host/webapp/webapp.tf`. These settings enable automatic scaling of the App Service Plan based on CPU usage metrics.

### Key Parameters

**File location:** `/infra/core/host/webapp/webapp.tf`

#### Scaling Rules

1. **Increase Capacity Rule:**
   - **Metric:** `CpuPercentage`
   - **Operator:** `GreaterThan`
   - **Threshold:** `60%`
   - **Time Window:** `5 minutes`
   - **Scaling Action:** Increase capacity by `1` with a cooldown of `5 minutes`.

2. **Decrease Capacity Rule:**
   - **Metric:** `CpuPercentage`
   - **Operator:** `LessThan`
   - **Threshold:** `20%`
   - **Time Window:** `10 minutes`
   - **Scaling Action:** Decrease capacity by `1` with a cooldown of `15 minutes`.

### Customization

To customize the App Service Plan Autoscale settings, modify the parameters mentioned above in the specified terraform files. And Run the `make infrastructure` command.

# SKU settings documentation

### Overview

The SKU settings for all Service Plans are defined in the file located at `/infra/variables.tf`.  The SKU (Stock Keeping Unit) represents the pricing tier or plan for your App Service. It defines the performance, features, and capacity of the App Service.
More information can be found [here.](https://azure.microsoft.com/pricing/details/app-service/windows/#purchase-options)

## Web App Service Plan SKU

**File location:** `/infra/variables.tf`

### SKU settings

- **appServiceSkuSize** `Pv2`

### Customization

To customize the App Service Plans SKU settings, modify the `sku` parameters in the specified Terraform file and run the `make deploy` or `make infrastructure`command.

This can also be adjusted in the Azure Portal.

**Note:** Adjusting the scale or Tier can cause outages until the redeployment occurs.

### Steps to scale up

>1. **Sign in to the Azure Portal:**
>   - Open a web browser and navigate to the [Azure Portal](https://portal.azure.com/).
>   - Log in with your Azure account credentials.
>2. **Navigate to the App Service:**
>   - In the left navigation pane, select "App Services".
>   - Click on the specific App Service you want to scale.
>3. **Access the Scale Up blade:**
>   - In the App Service menu, find and click on "Scale up (App Service plan)" in the left sidebar.
>4. **Choose a new pricing tier:**
>   - On the "Scale Up" blade, you'll see different pricing tiers representing various levels of resources.
>   - Select the desired pricing tier that corresponds to the scale you need.
>5. **Review and apply changes:**
>   - Review the information about the selected pricing tier, including its features and costs.
>   - Click the "Apply" or "Save" button to apply the changes.

### Considerations

- **Cost implications:**
  - Be aware of the cost implications associated with higher pricing tiers. Review the Azure Pricing documentation for details on costs.

- **Resource limits:**
  - Ensure that the new pricing tier aligns with the resource requirements of your application. Some tiers may have limitations on resources.

- **Performance impact:**
  - Scaling up provides additional resources, potentially improving performance. However, it's essential to assess whether your application benefits from the increased resources.
