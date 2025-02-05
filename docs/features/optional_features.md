# Information Assistant (IA) agent template optional features

Please see below sections for coverage of IA agent template optional features.

* [Configuring your own language ENV file](#configuring-your-own-language-env-file)
* [Debugging functions](#debugging-functions)
* [Debugging the web app](#debugging-the-web-app)
* [Debugging the enrichment web app](#debugging-the-enrichment-web-app)
* [Build pipeline for Sandbox](#build-pipeline-for-sandbox)
* [Customer Usage Attribution](#customer-usage-attribution)
* [Sovereign Region Deployment](#sovereign-region-deployment)
* [Secure Deployment](#secure-deployment)
* [Configure REST API access](#configure-rest-api-access)
* [Customize Autoscale and App Service SKU's](#customize-autoscale)

## Configuring your own language ENV file

At deployment time, you can alter the behavior of the IA agent template to use a language of your choosing across it's Azure AI Search and Azure OpenAI prompting. See [Configuring your own language ENV file](/docs/features/configuring_language_env_files.md) more information.

## Debugging functions

Check out how to [Debug the Azure functions locally in VSCode](/docs/function_debug.md)

## Debugging the web app

Check out how to [Debug the Information Assistant Web App](/docs/webapp_debug.md)

## Debugging the enrichment web app

Check out how to [Debug the Information Assistant Enrichment Web App](/docs/container_webapp_debug.md)

## Build pipeline for Sandbox

Setting up a pipeline to deploy a new Sandbox environment requires some manual configuration. Review the details of the [Procedure to setup sandbox environment](/docs/deployment/setting_up_sandbox_environment.md) here.

## Customer Usage Attribution

A feature offered within Azure, "Customer Usage Attribution" associates usage from Azure resources in customer subscriptions created while deploying your IP with you as a partner. Forming these associations in internal Microsoft systems brings greater visibility to the Azure footprint running the Information Assistant agent template.

Check out how to [enable Customer Usage Attribution](/docs/features/enable_customer_usage_attribution.md)

## Sovereign Region Deployment

Check out how to [setup Sovereign Region Deployment](/docs/deployment/enable_sovereign_deployment.md)

## Secure Deployment

Learn more about secure deployments and how to [enable a Secure Deployment](/docs/secure_deployment/secure_deployment.md)

## Configure REST API access

If you are wanting to use the API stand-alone or use a custom UI.
Check out how to [enable OAuth Client Credentials Flow](/docs/deployment/client_credentials_flow.md)

## Customize Autoscale

If you want to learn more about Autoscale Settings and App Service SKU's
Check out how to [customize Autoscale settings](/docs/deployment/autoscale_sku.md)
