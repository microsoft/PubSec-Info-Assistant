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

### Customization

To customize the Azure Functions Service Plan Autoscale settings, modify the parameters mentioned above in the specified Bicep file.

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

### Customization

To customize the App Service Plans SKU settings, modify the `sku` parameters in the specified Bicep file and run the `make deploy` or `make infrastructure`command.

