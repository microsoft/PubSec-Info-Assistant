# Troubleshooting


## Infrastructure Deployment
Please see below sections for troubleshooting the solution depending on what area of the process that is giving issue.


If you are having issues with infrastructure deployment then the errors should be apparent in the make deploy output.

You can also navigate to the Subscription in Azure portal, click the option for "Deployments" and find your deployment and related details and errors there.

Take the full error and logs and post them to this github repo Issues tab with your configuration used.

More info can be found [here](https://learn.microsoft.com/azure/azure-resource-manager/templates/deployment-history?tabs=azure-portal)

## File Processing

TBD

## Log Analytics Workbook

WebApp logs, Function logs and App Service logs can be found in Log Analytics Workspace.

There exist in this solution a workbook with default queries that can be used to explore and troubleshoot further.
Check out the section [Workbook Usage](/docs/deployment/workbook_usage.md).

For more information on log analytics and kusto query language, look [here](https://learn.microsoft.com/azure/azure-monitor/logs/queries?tabs=groupby).