<<<<<<< HEAD
=======
# Investigating File Processing Errors in CosmosDB Logs

>>>>>>> c3dca962f39fa8834aa70895953aef3409b92870
## Navigating to Azure Resource Group and Opening Cosmos Account Resource

>1. Log in to the Azure portal.
>2. In the left-hand menu, click on "Resource groups".
>3. Select the desired resource group from the list.
>4. In the resource group overview, locate and click on the Cosmos account resource.

<<<<<<< HEAD
![Alt text](/docs/images/cosmos_account.png)
=======
![CosmosDB Azure Portal Blade View](/docs/images/cosmos_account.png)
>>>>>>> c3dca962f39fa8834aa70895953aef3409b92870

## Accessing Data Explorer

>1. Once you are on the Cosmos account resource page, navigate to the left-hand menu.
>2. Under the "Settings" section, click on "Data Explorer".

<<<<<<< HEAD
![Alt text](/docs/images/data_explorer.png)
=======
![CosmosDB Azure Portal Data Explorer View](/docs/images/data_explorer.png)
>>>>>>> c3dca962f39fa8834aa70895953aef3409b92870

## Expanding the Database

>1. In the Data Explorer, you will see a list of databases associated with the Cosmos account.
>2. Locate the "statusdb" database and click on it to expand.

## Viewing the Items Table

>1. Within the expanded "statusdb" database, you will find a list of containers (tables).
>2. Look for the "items" table and click on it.

## Checking File Processing Status and Errors

>1. Once you are on the "items" table page, you will see a list of items (documents) in the table.
>2. Each item represents a file being processed.
>3. Look for the "status" field to see the status of each file being processed.
<<<<<<< HEAD
>4. If there are any associated errors, they will be displayed in the "errors" field.
=======
>4. If there are any associated errors, they will be displayed in the "errors" field.
>>>>>>> c3dca962f39fa8834aa70895953aef3409b92870
