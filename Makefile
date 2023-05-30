SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
        | column -t -s '|'

deploy: build infrastructure extract-env deploy-search-indexes deploy-webapp deploy-functions ## Deploy infrastructure and application code
 
build: ## Build application code
	@./scripts/build.sh

infrastructure: check-subscription ## Deploy infrastructure
	@./scripts/inf-create.sh

extract-env: extract-env-debug## Extract infrastructure.env file from BICEP output
	@./scripts/json-to-env.sh < infra_output.json > ./scripts/environments/infrastructure.env

deploy-webapp: extract-env ## Deploys the web app code to Azure App Service
	@./scripts/deploy-webapp.sh

deploy-functions: extract-env ## Deploys the function code to Azure Function Host
	@./scripts/deploy-functions.sh

deploy-search-indexes: extract-env ## Deploy search indexes
	@./scripts/deploy-search-indexes.sh

extract-env-debug: ## Extract infrastructure.debug.env file from BICEP output
	@./scripts/json-to-env.debug.sh < infra_output.json > ./scripts/environments/infrastructure.debug.env


# Utils (used by other Makefile rules)
check-subscription:
	@./scripts/check-subscription.sh 

# CI rules (used by automated builds)
take-dir-ownership:
	@sudo chown -R vscode .

destroy-inf: check-subscription
	@./scripts/inf-destroy.sh
