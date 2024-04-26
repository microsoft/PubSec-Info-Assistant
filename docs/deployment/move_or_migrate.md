# Moving from 1.0 to 1.1

As customers move from 1.0 to the 1.1 release we have heard some have the the desire to maintain their processed content rather than reprocessing. While this would be optimal from an experience perspective, it can be complex at a technical level. We understand the request and have provided capabilities to assist. **To be clear our recommended approach to onboarding to the 1.1 version would be to create a new deployment in a new resource group**. 

If you feel strongly that you need to maintain your content, without reprocessing we have provided sample code to enable you to do this in two ways, namely to upgrade your 1.0 deployment to 1.1 or alternatively to migrate your 1.0 deployment data to the 1.1 deployment. The recommended approach would be to migrate, as this poses the least risk to your existing processed data. Let's explore these options in a bit more depth.

As a first step, ensure your environment is up to date, by executing the following commands:

```python
pip install --upgrade azure-core
pip install --azure-keyvault-secrets
```

## Migrate ##
The migrate path is where you deploy a 1.1 resource group while maintaining your 1.0 deploymmet. Then you move the data, specifically serach index, storage account data and cosmos db documents, from your 1.0 deploymmet to your new 1.1 deployment. Of the two paths this option poses least risk, as it does not make any changes to your existing 1.0 deployment. This is the recommended path if you and not willing to start with a fresh deployment of 1.1. 

The risks, or tradeoffs, of taking the migrate path are:
- As you are migrating to a new deployment, your users will need to switch to the new web urls to access the service. 
- You will need to retire any old 1.0 services once clients have adopted the new deployment as charges will still build up on these.

The benefits are:
- This is a simpler approach than performing an in place upgrade, where your existing services are not part of the new deployment and therefore are not at risk of being deleted by this new deployment.
- Users will not be impacted significantly while the deployment is underway. 

Find more details [here](migrate.md). 

## Upgrade ##
In this option we overlay the 1.1 assets onto the existing 1.0 deployment, using the same services and resource group. One of the challenges with this approach is that we use a different technology to deploy the services in 1.1 than we do in 1.0, namely Bicep in 1.1 and Terraform in 1.1. 

The risks or tradeoffs of doing the upgrade approach are:
- While the upgrade is underway your users will not be able to reliably access the service
- If you do not correctly assess the plan Terraform makes for how it will modify, create or delete services, you could approve the deletion of one of the services you are trying to preserve, namely Cosmos DB, Storage Account and the Search Service. This could result in these services and the associated data being deleted.
- If you have made significant changes at an infrastructure level, such as renaming identities or services, you will need to tailor the sample code.
- This path is technically much more complex

The benefits are:
- Your clients will use the same resources, and so they will not have to change where they access the service

Find out more about the upgrade path  [here](upgrade.md). 

## Summary
In summary again, our recommended approach for simplicity is to **create a new deployment of the 1.1 code base**. If you feel the need to keep your preprocessed content then take the upgrade or migration option, but be aware that this can be tricky and will require technical expertise to validate the plans and execution and possibly modification of the example code we have provided. We suggest you plan the deployment carefully and try it in a sandbox environment first to familiarize yourself with the steps.