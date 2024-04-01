# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
        | column -t -s '|'

deploy: build infrastructure extract-env deploy-enrichments deploy-search-indexes deploy-webapp deploy-functions ## Deploy infrastructure and application code
 
build-deploy-webapp: build extract-env deploy-webapp ##Build and Deploy the Webapp
build-deploy-enrichments: build extract-env deploy-enrichments ##Build and Deploy the Enrichment Webapp
build-deploy-functions: build extract-env deploy-functions ##Build and Deploy the Functions

build: ## Build application code
	@./scripts/build.sh

build-containers: extract-env
	@./app/enrichment/docker-build.sh

infrastructure: check-subscription ## Deploy infrastructure
	@./scripts/inf-create.sh

extract-env: extract-env-debug-webapp extract-env-debug-functions ## Extract infrastructure.env file from BICEP output
	 @./scripts/json-to-env.sh < inf_output.json > ./scripts/environments/infrastructure.env

deploy-webapp: extract-env ## Deploys the web app code to Azure App Service
	@./scripts/deploy-webapp.sh

deploy-functions: extract-env ## Deploys the function code to Azure Function Host
	@./scripts/deploy-functions.sh

deploy-enrichments: extract-env ## Deploys the web app code to Azure App Service
	@./scripts/deploy-enrichment-webapp.sh

deploy-search-indexes: extract-env ## Deploy search indexes
	@./scripts/deploy-search-indexes.sh

extract-env-debug-webapp: ## Extract infrastructure.debug.env file from BICEP output
	@./scripts/json-to-env.webapp.debug.sh < inf_output.json > ./scripts/environments/infrastructure.debug.env

extract-env-debug-functions: ## Extract local.settings.json to debug functions from BICEP output
	@./scripts/json-to-env.function.debug.sh < inf_output.json > ./functions/local.settings.json

# Utils (used by other Makefile rules)
check-subscription:
	@./scripts/check-subscription.sh 

# CI rules (used by automated builds)
take-dir-ownership:
	@sudo chown -R vscode .

terraform-remote-backend:
	@./scripts/terraform-remote-backend.sh

infrastructure-remote-backend: terraform-remote-backend infrastructure

destroy-inf: check-subscription
	@./scripts/inf-destroy.sh

functional-tests: extract-env ## Run functional tests to check the processing pipeline is working
	@./scripts/functional-tests.sh	

import-state: check-subscription ## import state of current srevcies to TF state
	@./scripts/inf-import-state.sh

merge-databases: ## merge the status and tags db's to the status db
	python ./scripts/merge-databases.py

inject-dependencies: ## merge the status and tags db's to the status db
	python ./scripts/inf-inject-dependencies.py

# Command to merge databases and import TF state in prep for an upgrade from 1.0 to 1.n
prep-upgrade: merge-databases import-state inject-dependencies
