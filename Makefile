SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m|%s\n", $$1, $$2}' \
        | column -t -s '|'

deploy: build infrastructure extract-env deploy-search-indexes deploy-webapp ## Deploy infrastructure and application code
 
build: ## Build application code
	@./scripts/build.sh

infrastructure: check-subscription ## Deploy infrastructure
	@./scripts/inf-create.sh

extract-env: ## Extract infrastructure.env file from terraform output
	@./scripts/json-to-env.sh < infra_output.json > ./scripts/environments/infrastructure.env

prep-data: extract-env ## Prepare data and deploy search indexes
	@./scripts/prep-data.sh

remove-all-data: extract-env ## Remove all test data added to the index manually
	@./scripts/remove-all-data.sh

deploy-webapp: extract-env ## Deploys the web app to Azure App Service
	@./scripts/deploy-webapp.sh

deploy-search-indexes: extract-env 
	@./scripts/deploy-search-indexes.sh

# Utils (used by other Makefile rules)
check-subscription:
	@./scripts/check-subscription.sh