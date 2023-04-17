# Configure Azure resources

Now that your Dev Container and ENV files are configured, it is time to deploy the Azure resources. This is done using a `Makefile`.

To deploy everything run the following command from the Dev Container bash prompt:

```bash
    make deploy
```

This will deploy the infrastructure and the application code.

*This command cam be run as many times as needed in the event you encounter any errors. A set of known issues and their workarounds that we have found can be found in [Known Issues](../docs/knownissues.md)*

---

At this point this step is complete, please return to the [checklist](../README.md#deployment)) and complete the next step.

## Additional Information

For a full set of Makefile rules, run `make help`.

``` bash
vscode ➜ /workspaces/osint (main ✗) $ make help
help                            Show this help
deploy                          Deploy infrastructure and application code
build                           Build application code
infrastructure                  Deploy infrastructure
deploy-webapp                   Deploys the web app to Azure App Service
deploy-search-indexes           Deploy search indexes
extract-env                     Extract infrastructure.env file from BICEP output
```
