# Migrate from 1.0 to 1.1

Before you perform a migration, we recommend you review the sample code and test both 1.0 and 1.1 deployments in a sandbox resource group first. Once comfortable, move forward with the following steps:

1. Deploy v1.1 into a new resource group. Follow the [standard steps](/docs/deployment/deployment.md) to deploy 1.1. Once complete, test and validate it has completed successfully.
2. Copy the file `/scripts/upgrade_repoint.config.json.example` to a new file and name it `upgrade_repoint.config.json`. Edit this file and add the name of your old 1.0 resource group and the 5 character random text suffix from that resource group under the section **old_env**. Next, add the name of your newly deployed 1.1 resource group and the 5 character random suffix from that resource group to the section **new_env**.

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

3. You will need to have the correct privileges to read from the existing 1.0 resources. It is recommended to log in to Azure via VSCode using the same user that performed the original deployment of 1.0. If you can't do this, then run the command below. This will assign the required permissions to the user account performing the migration (i.e example rights to read secrets from Key Vault).

```bash
make prep-migration-env
```

4. Next, the migration needs to make some surgical updates to the Cosmos DB instance. (Copy the tag arrays from the tagsdb to the statusdb) To perform this action run the command below in a terminal window in VSCode

```bash
make merge-databases
```

5. Next, the migration will export the data from the search indexes, Cosmos DB, and the storage account from v1.0 to the same services in the 1.1 deployment. To do this run the command:

```bash
make run-data-migration
```

Once complete, the new deployment of 1.1 should be functional and contain the processed content from your 1.0 deployment. You can now begin planning for retirement of your old 1.0 deployment.

## Re-running a migration

If you encounter a failure  while running the migration, you can re-run the process, but you have the option to skip steps to avoid repetition. You have the option of setting these values to True in the file `/scripts/extract-content.py`:

```bash
skip_search_index = False
skip_cosmos_db = False
skip_upload_container = False
skip_content_container = False
```
