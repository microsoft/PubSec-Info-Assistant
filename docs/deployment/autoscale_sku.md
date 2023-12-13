# Autoscale Settings Documentation

These are the current out of the box Autoscale settings.
You may find better settings to fit your needs. This document explains how this can be accomplished.

## Azure Functions Service Plan Autoscale

### Overview

The Azure Functions Service Plan Autoscale settings are defined in the file located at `/infra/core/host/funcserviceplan.bicep`. These settings enable automatic scaling of the Azure Functions Service Plan based on CPU usage metrics.



 **File Location:** `/infra/core/host/funcserviceplan.bicep`

#### Scaling Rules

1. **Increase Capacity Rule:**
   - **Metric:** `CpuPercentage`
   - **Operator:** `GreaterThan`
   - **Threshold:** `60%`
   - **Time Window:** `5 minutes`
   - **Scaling Action:** Increase capacity by `2` with a cooldown of `5 minutes`.

2. **Decrease Capacity Rule:**
   - **Metric:** `CpuPercentage`
   - **Operator:** `LessThan`
   - **Threshold:** `40%`
   - **Time Window:** `5 minutes`
   - **Scaling Action:** Decrease capacity by `2` with a cooldown of `2 minutes`.


## App Service Plan Autoscale for Enrichment App

### Overview

The App Service Plan Autoscale settings for the enrichment app are defined in the file located at `/infra/core/host.enrichmentappserviceplan.bicep`. These settings enable automatic scaling of the App Service Plan based on CPU usage metrics.

### Key Parameters

**File Location:** `/infra/core/host.enrichmentappserviceplan.bicep`

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

To customize the App Service Plan Autoscale settings, modify the parameters mentioned above in the specified Bicep file. And Run the `make infrastructure` command.



# SKU Settings Documentation

### Overview

The SKU settings for all Service Plans are defined in the file located at `/infra/main.bicep`.  The SKU (Stock Keeping Unit) represents the pricing tier or plan for your App Service. It defines the performance, features, and capacity of the App Service. 
More information can be found [here.](https://azure.microsoft.com/en-us/pricing/details/app-service/windows/#purchase-options)

## Web App Service Plan SKU


**File Location:** `/infra/main.bicep`

#### SKU Settings

- **Name:** `S1`
- **Capacity:** `3`


## Functions Service Plan SKU


**File Location:** `/infra/main.bicep`

#### SKU Settings

- **Name:** `S2`
- **Capacity:** `2`

## Enrichment App Service Plan SKU


**File Location:** `/infra/main.bicep`

#### SKU Settings

- **Name:** `P1v3`
- **Tier:** `PremiumV3`
- **Size:** `P1v3`
- **Family:** `Pv3`
- **Capacity:** `1`

### Enrichment Message Dequeue Parameter
There exist a property that can be set int he local.env file called `DEQUEUE_MESSAGE_BATCH_SIZE` and is defaulted in the `infra/main.bicep` and `app/enrichment/app.py` to the value of **3**. This means the app will process 3 messages from the queue at a time. This is found to be the most opitmal with the existing configuration but can be increased if you also increase tne enrichment app service SKU. It is important to note that there will be issues if it is increased more than the app service SKU can handle.

### Customization

To customize the App Service Plans SKU settings, modify the `sku` parameters in the specified Bicep file and run the `make deploy` or `make infrastructure`command.

This can also be adjusted in the Azure Portal.

**Note:** Adjusting the scale or Tier can cause outages until the redeployment occurrs.


### Steps to Scale Up:

>1. **Sign in to the Azure Portal:**
>   - Open a web browser and navigate to the [Azure Portal](https://portal.azure.com/).
>   - Log in with your Azure account credentials.

>2. **Navigate to the App Service:**
>   - In the left navigation pane, select "App Services."
>   - Click on the specific App Service you want to scale.

>3. **Access the Scale Up Blade:**
>   - In the App Service menu, find and click on "Scale up (App Service plan)" in the left sidebar.

>4. **Choose a New Pricing Tier:**
>   - On the "Scale Up" blade, you'll see different pricing tiers representing various levels of resources.
>   - Select the desired pricing tier that corresponds to the scale you need.

>5. **Review and Apply Changes:**
>   - Review the information about the selected pricing tier, including its features and costs.
>   - Click the "Apply" or "Save" button to apply the changes.


### Considerations:
- **Cost Implications:**
  - Be aware of the cost implications associated with higher pricing tiers. Review the Azure Pricing documentation for details on costs.

- **Resource Limits:**
  - Ensure that the new pricing tier aligns with the resource requirements of your application. Some tiers may have limitations on resources.

- **Performance Impact:**
  - Scaling up provides additional resources, potentially improving performance. However, it's essential to assess whether your application benefits from the increased resources.

By following these steps, you can successfully scale up your Azure App Service to accommodate increased workloads or resource requirements.
