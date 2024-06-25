# Azure Workbook Template - Log Analysis

## Overview

The Azure Workbook template `infoasst-lw-xxxx` is designed for log analysis, providing insights into different types of logs within your Azure environment. The template is organized into three sections:

1. **Application Logs (Last 6 Hours)**
   - Application logs are retrieved from the `AppServiceConsoleLogs`.
   - Default Query:
     ```kql
     AppServiceConsoleLogs 
     | project TimeGenerated, ResultDescription, _ResourceId 
     | where TimeGenerated > ago(6h) 
     | order by TimeGenerated desc
     ```

2. **Function Logs (Last 6 Hours)**
   - Function logs are obtained from the `AppTraces`.
   - Default Query:
     ```kql
     AppTraces 
     | project TimeGenerated, Message, Properties 
     | where TimeGenerated > ago(6h) 
     | order by TimeGenerated desc
     ```

3. **App Service Deployment Logs (Last 6 Hours)**
   - App service and deployment logs are sourced from `AppServicePlatformLogs`.
   - Default Query:
     ```kql
     AppServicePlatformLogs 
     | project TimeGenerated, Level, Message, _ResourceId 
     | where TimeGenerated > ago(6h) 
     | order by TimeGenerated desc
     ```

## Usage

To effectively use this template, follow these steps:


>1. From the Azure Portal Resource Group Open the resource >`infoasst-lw-xxxx`
>
>2. Explore log data using the predefined queries, or modify them in the portal by clicking Edit in the workbook to troubleshoot specific issues. Adjust the time range and filters as needed.

## Customization

If you need to customize the default queries, locate the respective sections in the Terraform file and modify the `query` field within the `content` property.

Feel free to adapt the template based on your specific log analysis requirements.
