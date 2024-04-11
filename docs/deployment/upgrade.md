# Migrating to 1.1 from 1.0

As customers move from 1.0 to the 1.1 release we have heard some have the the desire to maintain their processed content rather than reprocessing. While this would be optimal from an experience perspective, it can be complex at a technical level. We understand the request and have provided capabilities to assist. **To be clear our recommended approach to onboarding to the 1.1 version would be to create a new deployment in a new resource group**. 

If you feel strongly that you need to maintain your content, without reprocessing we have provided sample code to enable you to do this in two ways, namely to upgrade your 1.0 deployment to 1.1 or alternatively to repoint your 1.1 deployment to the 1.0 deployment. The recommended approach would be to repoint, as this poses the least risk to your existing precessed data. Let's explore these options in a bit more depth.

As a first step, ensure your environment is up to date, by executing the following commands:

```python
pip install --upgrade azure-core
pip install --azure-keyvault-secrets
```

## Upgrade 
In this option we overlay the 1.1 assets onto the existing 1.0 deployment, using the same services and resource group. One of the challenges with this approach is that we use a different technology to deploy the services in 1.1 than we do in 1.0, namely Bicep in 1.1 and Terraform in 1.1. The risks or tradeoffs of doing the upgrade approach are:
- While the upgrade is underway your users will not be able to reliably access the service
- If you do not correctly assess the plan Terraform makes for how it will modify, create or delete services, you could approve the deletion of one of the services you are trying to preserve, namely Cosmos DB, Storage Account and the Search Service. This could result in these services and the associated   data being deleted.
- If you have made significant changes at an infrastructure level, such as renaming identities or services, you will need to tailor the sample code.

The benefits are:
- Once deployed, you will only have a single instance going forward

### Steps to upgrade
To perform an upgrade, ideally review the sample code and test in a sandbox resource group deployment of 1.0. Once happy, more forward with the following steps:
- Copy the file named upgrade_repoint.config.json.example in the /scripts folder and name it upgrade_repoint.config.json. Edit this file and add the name of your old 1.0 resource group and the 5 character random text suffix applied to all the Azure services in that resource group. Additionally add these same values to the section marked new_env, as technically your new environment and old environments will be the same resource group.

```json
{
"old_env":
    {
        "resource_group": "",
        "random_text": ""
    },
"new_env":
    {
        "resource_group": "",
        "random_text": ""
    }
}
```
- Next you need to make some surgical changes to the Cosmos DB instance, where we copy the tag arrays from the tagsdb to the statusdb. To perform this action run the command below in a terminal window
```bash
make merge-databases
```
- Next we need to review the deployed 1.0 services and build a Terraform state file, so GTerraform understand the existing deployment and can determine which services need to be upgraded, deleted or left untouched when we upgrade to 1.1. To do this run the command:
```bash
make import-state
```
- Once this command has completed processing, review the status output to determine if any service's states were not imported. If any failed, rerun or investigate why they failed.
- Now we have created a state file, we need to augment it with a few items that were not possible to import, but are required for us to overlay the 1.1 deployment on your 1.0 instance. To inject these items perform the following command:
```bash
make inject-dependencies
```
- We should highlight the above 3 commands can be executed as a single process by running the command, but it is advisable to do each step independently.
```bash
make prep-upgrade
```
- Now we have the state file ready. Terraform will understand the existing services, and will therefore be able to assess what needs to change when we deploy the 1.1 codebase into this resource group. To start this process, as with a normal deployment run the command:
```bash
make deploy
```
After running these steps, if successful, you will have the 1.1 assets running within your original resource group. **It is imperative that during the make deploy process that you review the terraform plan to validate your old (1.0) services will not be deleted. To achieve this ensure that you carefully review the plan presented to you during the make infrastructure step, to ensure your services are maintained.**

## Repoint
In this approach you can make a fresh deployment of 1.1 and repoint the various services to the content focused services in the old 1.0 deployment. Taking this approach removes the complexity associated with overlaying a Terraform managed deployment onto an existing deployment. The risks or tradeoffs of doing the upgrade approach are:
- You will have 2 separate resource groups to maintain going forward
- It may be complex to upgrade to any future versions as they will not natively assume you have this repointing scenario. This would require you to perform repointing every time you recreate the infrastructure due to adopting a newer version.
- As you are migrating to a new deployment, your users will need to switch to the new web urls to access the service. 

The benefits are:
- This is a  simpler approach than performing an in place upgrade, where your existing stateful services, Cosmos DB, Storage Account and the Search Service are not part of the new deployment and therefore are not at risk of being deleted by this new deployment.
- USers will not be impacted significantly while the deployment is underway. 

### Steps to repoint
To perform an upgrade, ideally review the sample code and test in a sandbox resource group deployment of 1.0 and 1.1 deployments. Once happy, more forward with the following steps:
- Create your new deployment of 1.1 in a new resource group. Create the local.env file with your desired configurations and follow the standard steos to depoloy 1.1. Once complete, test it to validate it has completed successfully. 
Copy the file named upgrade_repoint.config.json.example in the /scripts folder and name it upgrade_repoint.config.json. Edit this file and add the name of your old 1.0 resource group and the 5 character random text suffix applied to all the Azure services in that resource group. Next, add the values of your newly deployed 1.1 resource group and the 5 character random suffix applied to services in that resource group to the section new_env.

```json
{
"old_env":
    {
        "resource_group": "",
        "random_text": ""
    },
"new_env":
    {
        "resource_group": "",
        "random_text": ""
    }
}
```
- Next you need to make some surgical changes to the Cosmos DB instance, where we copy the tag arrays from the tagsdb to the statusdb. To perform this action run the command below in a terminal window
```bash
make merge-databases
```
- Next we need to update all configuration references in the various apps to point at the key vault, storage account, cosmos db and search index in the old 1.0 deployment. To do this run the following command in a terminal:
```bash
make run-repoint
- 
```
- We should highlight the above 3 commands can be executed as a single process by running the command, but it is advisable to do each step independently.
```bash
make repoint
```
Once complete, your new deployment of 1.1 should be functional and pointing at the existing processed content stored in your old 1.0 resource group.

## Summary
In summary again, our recommended approach for simplicity is to **create a new deployment of the 1.1 code base**. If you fee the need to keep your preprocessed content then take the upgrade or repoint option, but be aware that this can be tricky and will require technical expertise to validate the plans and execution, possibly modification of the example code we have provided. We suggest you plan the deployment carefully and try it in a sandbox environment first to familiarize yourself with the steps.