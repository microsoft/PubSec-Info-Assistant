# IA Accelerator Optional Features

Please see below sections for coverage of IA Accelerator optional features.

* [Configuring your own language ENV file](/docs/features/features.md#configuring-your-own-language-env-file)
* [Debugging functions](/docs/features/features.md#debugging-functions)
* [Debugging the web app](/docs/features/features.md#debugging-the-web-app)
* [Debugging the container web app](/docs/features/features.md#debugging-the-container-web-app)
* [Build pipeline for Sandbox](/docs/features/features.md#build-pipeline-for-sandbox)
* [Customer Usage Attribution](/docs/features/features.md#customer-usage-attribution)
* [Sovereign Region Deployment](/docs/features/features.md#sovereign-region-deployment)
* [Configure REST API access](#configure-rest-api-access)

## Configuring your own language ENV file

At deployment time, you can alter the behavior of the IA Accelerator to use a language of your choosing across it's Azure Cognitive Search and Azure OpenAI prompting. See [Configuring your own language ENV file](/docs/features/configuring_language_env_files.md) more information.

## Debugging functions

Check out how to [Debug the Azure functions locally in VSCode](/docs/function_debug.md)

## Debugging the web app

Check out how to [Debug the Information Assistant Web App](/docs/webapp_debug.md)

## Debugging the container web app

Check out how to [Debug the Information Assistant Web App](/docs/container_webapp_debug.md)

## Build pipeline for Sandbox

Setting up a pipeline to deploy a new Sandbox environment requires some manual configuration. Review the details of the [Procedure to setup sandbox environment](/docs/deployment/setting_up_sandbox_environment.md) here.

## Customer Usage Attribution

A feature offered within Azure, "Customer Usage Attribution" associates usage from Azure resources in customer subscriptions created while deploying your IP with you as a partner. Forming these associations in internal Microsoft systems brings greater visibility to the Azure footprint running the Information Assistant Accelerator.

Check out how to [enable Customer Usage Attribution](/docs/features/enable_customer_usage_attribution.md)

## Sovereign Region Deployment

Check out how to [setup Sovereign Region Deployment](/docs/deployment/enable_sovereign_deployment.md)

## Configure REST API access

If you are wanting to use the API stand-alone or use a custom UI.
Check out how to [enable OAuth Client Credentials Flow](/docs/deployment/client_credentials_flow.md)
