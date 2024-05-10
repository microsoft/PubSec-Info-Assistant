# Upgrade from 1.0 to 1.1

To perform an upgrade, ideally review the sample code and test in a sandbox resource group deployment of 1.0. Once prepared, move forward with the following steps:

1. Create a copy of the `local.env` file, which should have the same values that were used to deploy your old 1.0 resource group. This will be used as a reference going forward as the `local.env` file has changed in 1.1.
2. Copy the file `/scripts/upgrade_repoint.config.json.example` to a new file and name it `upgrade_repoint.config.json`. Edit this file and add the name of your old 1.0 resource group and the 5 character random text suffix applied to all the Azure services in that resource group. Additionally add these same values to the section marked new_env, as technically your new environment and old environments will be the same resource group.

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

3. Before deploying version 1.1 you will need to ensure you have the correct permissions to update the existing resources. Be sure to log in to Azure within VS Code using the same user that performed the original deployment of 1.0. If you can't do this, then run the command below. This will assign the required permissions to the user account performing the upgrade. (i.e. rights to read secrets from Key Vault and assigning the user as owners of the various application registrations) To do this the account you are using will need the Microsoft Entra role of Application Administrator or request the user account to be made owner of the app registrations:

>- infoasst-enrichmentweb-<random_text_suffix>
>- infoasst-web-<random_text_suffix>
>- infoasst-func-<random_text_suffix>

```bash
make prep-env
```

4. Next you need to make some surgical changes to the Cosmos DB instance, where we copy the tag arrays from the tagsdb to the statusdb. To perform this action run the command below in a terminal window

```bash
make merge-databases
```

5. Next we need to review the deployed 1.0 services and build a Terraform state file, so Terraform understand the existing deployment and can determine which services need to be upgraded, deleted or left untouched when we upgrade to 1.1. To do this run the command:

*IMPORTANT: Before you run `make import-state` ensure your `local.env` is correctly configured to match your 1.0 resource group and deployment settings.*

```bash
make import-state
```

6. Once this command has completed processing, review the status output to determine if any service's states were not imported. If any failed, rerun or investigate why they failed.
7. Now we have the state file ready. Terraform will understand the existing services, and will therefore be able to assess what needs to change when we deploy the 1.1 code base into this resource group. To start this process, as with a normal deployment run the command:

```bash
make deploy
```

:warning: **It is imperative that during the make deploy process that you review the terraform plan to validate your old (1.0) services will not be deleted. The key services are the storage account, cosmos DB, key vault, and the search index. To achieve this ensure that you carefully review the plan presented to you during the make infrastructure step, to ensure your services are maintained.**

After running these steps, you will have the 1.1 assets running within your original resource group.
