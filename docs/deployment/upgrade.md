# Migrating to 1.1 from 1.0

As customers move from 1.0 to the 1.1 release we have heard some have the the desire to maintain their processed content rather than reprocessing. While this would be optimal from an experience perspective, it can be complex at a technical level. We understand the request and have provided capabilities to assist. **To be clear our recommended approach to onboarding to the 1.1 version would be to create a new deployment in a new resource group**. 

If you feel strongly that you need to maintain your content, without reprocessing we have provided sample code to enable you to do this in two ways, namely to upgrade your 1.0 deployment to 1.1 or alternatively to migrate your 1.0 content to the 1.1 deployment. The recommended approach would be to migrate, as this poses the least risk to your existing precessed data. Let's explore these options in a bit more depth.

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
- Create a version of the Local.env file, which should have the same values that were used to deploy your old 1.0 resource group.
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
- We should highlight the above commands can be executed as a single process by running the command, but it is advisable to do each step independently.
```bash
make prep-upgrade
```
- Before deploying version 1.1 you will need to ensure you have the correct privileges to update the existing resources. Ideally log in to Azure through vs code using the same user id that did the roiginal deployment of 1.0. If you can't do this, then run the command below. THis will assign the required permissions to the user account perfomring the upgrade, for example rights to read secrest from Kwy Vault and assigning the user as owners of the variious application registrations. To do this you the account you are using will need the role of Application Administrator. Alternatively request the account to be made owner of the app registrations:
    - infoasst-enrichmentweb-<random_text_suffix>
    - infoasst-web-<random_text_suffix>
    - infoasst-func-<random_text_suffix> 
```bash
make prep-env
```
- Now we have the state file ready. Terraform will understand the existing services, and will therefore be able to assess what needs to change when we deploy the 1.1 codebase into this resource group. To start this process, as with a normal deployment run the command:
```bash
make deploy
```
After running these steps, if successful, you will have the 1.1 assets running within your original resource group. **It is imperative that during the make deploy process that you review the terraform plan to validate your old (1.0) services will not be deleted. The key servcies are the stirage account, cosmos db, key vault and the search index. To achieve this ensure that you carefully review the plan presented to you during the make infrastructure step, to ensure your services are maintained.**

## Migrate your data
In this approach you can make a fresh deployment of 1.1 and move the data associated with certain servcies from those servcies in your old 1.0 deployment to your new 1.1 deployment. Taking this approach removes the complexity associated with overlaying a Terraform managed deployment onto an existing deployment. The risks or tradeoffs of doing the upgrade approach are:
- You will need to ensure you have the required rights to perform the migration. This isn't an issue if the same id used to do the 1.0 deployment is being used to do the 1.1 deployment
- As you are migrating to a new deployment, your users will need to switch to the new web urls to access the service. 

The benefits are:
- This is a simpler approach than performing an in place upgrade.
- Users will not be impacted significantly while the deployment is underway.

### Steps to repoint
To perform an data migration, ideally review the sample code and test in a sandbox resource group deployment of 1.0 and 1.1 deployments. Once happy, more forward with the following steps:
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
- Before deploying version 1.1 you will need to ensure you have the correct privileges to update the existing resources. Ideally log in to Azure through vs code using the same user id that did the roiginal deployment of 1.0. If you can't do this, then run the command below. This will assign the required permissions to the user account perfomring the upgrade, for example rights to read secrets from Key Vault.
```bash
make prep-migration-env
```
- Next you will initiate the migration by running the following command, which will copy data from the search index, Cosmos DB and the storage account from the 1.0 resource group to the 1.1 resource group.
```bash
make run-data-migration
```

Once complete, your new deployment of 1.1 should be functional and have thecontent stored in your old 1.0 resource group.

## Summary
In summary again, our recommended approach for simplicity is to **create a new deployment of the 1.1 code base**. If you feel the need to keep your preprocessed content then take the upgrade or data migration option, but be aware that this can be tricky and will require technical expertise to validate the plans and execution, possibly modification of the example code we have provided. We suggest you plan the deployment carefully and try it in a sandbox environment first to familiarize yourself with the steps.