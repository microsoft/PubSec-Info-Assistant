# Migrate from 1.0 to 1.1

To perform a migration, ideally review the sample code and test in a sandbox resource group deployment of 1.0 and 1.1 deployments. Once happy, more forward with the following steps:

- Create your new deployment of 1.1 in a new resource group. Create the local.env file with your desired configurations and follow the standard steps to depoloy 1.1. Once complete, test it to validate it has completed successfully. 
- Copy the file named upgrade_repoint.config.json.example in the /scripts folder and name it upgrade_repoint.config.json. Edit this file and add the name of your old 1.0 resource group and the 5 character random text suffix applied to all the Azure services in that resource group. Next, add the values of your newly deployed 1.1 resource group and the 5 character random suffix applied to services in that resource group to the section new_env.

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
- You will need to ensure you have the correct privileges to read from the existing 1.0 resources. Ideally log in to Azure through vs code using the same user id that did the roiginal deployment of 1.0. If you can't do this, then run the command below. This will assign the required permissions to the user account performing the upgrade, for example rights to read secrets from Key Vault.
```bash
make prep-migration-env
```
- Next you need to make some surgical changes to the Cosmos DB instance, where we copy the tag arrays from the tagsdb to the statusdb. To perform this action run the command below in a terminal window
```bash
make merge-databases
```
- Next we need to export the data from the search indexes, Cosmos DB, and the storage account to these services in the 1.1 deployment. To do this run the command:
```bash
make run-data-migration
```
Once complete, your new deployment of 1.1 should be functional and contain the processed content from your 1.0 deployment. You can now plan to retire you old 1.0 deployment.

## Re-running a migration
If you encounter a failure  while running the migration, you can re-run the process, but you have the option to skip steps to avoid repetition. You have the option of setting these values to True in the file called extract-content.py in the scripts folder:
```bash
skip_search_index = False
skip_cosmos_db = False
skip_upload_container = False
skip_content_container = False
```