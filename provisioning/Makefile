#----------------------------------------------------------------
# Variables
#----------------------------------------------------------------
CURRENT_BRANCH      := $(shell git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/-/g')
CURRENT_COMMIT_HASH := $(shell git rev-parse --short=10 HEAD)
DEPLOY_VERSION      := $(CURRENT_BRANCH)-$(CURRENT_COMMIT_HASH)

# Configuration
STACK               ?= prod-fra1
PROVISIONING_DIR    := ./provisioning
SECRETS_FILE        := $(PROVISIONING_DIR)/stacks/secrets.yaml

# Atmos Commands
ATMOS               := atmos
TERRAFORM           := terraform

#----------------------------------------------------------------
# SOPS Logic
#----------------------------------------------------------------
# This section re-runs the Makefile inside 'sops exec-env' 
# ensuring all secrets are available as real environment variables.
#----------------------------------------------------------------
export _SOPS_EXPORTED

ifndef _SOPS_EXPORTED
%:
	@echo "Decrypting secrets for $(STACK)..."
	@$(eval _SOPS_EXPORTED := 1)
	@sops exec-env $(SECRETS_FILE) "$(MAKE) $@"
else

#----------------------------------------------------------------
# Infrastructure Targets (Atmos)
#----------------------------------------------------------------

# Full Bootstrap using the Atmos Workflow
bootstrap:
	@echo "Provisioning full cluster stack: $(STACK)"
	cd $(PROVISIONING_DIR) && $(ATMOS) workflow provision-cluster -s $(STACK)

# Teardown
destroy: confirm-destroy
	@echo "Destroying full cluster stack: $(STACK)"
	cd $(PROVISIONING_DIR) && $(ATMOS) workflow destroy-cluster -s $(STACK)

# Component-specific targets
# Usage: make apply-networking, make plan-k3s-cluster
apply-%:
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) apply $* -s $(STACK)

plan-%:
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) plan $* -s $(STACK)

validate:
	@echo "🔍 Validating all Terraform components..."
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) validate networking -s $(STACK)
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) validate iam -s $(STACK)
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) validate vault -s $(STACK)
	cd $(PROVISIONING_DIR) && $(ATMOS) $(TERRAFORM) validate k3s-cluster -s $(STACK)

#----------------------------------------------------------------
# Application Targets
#----------------------------------------------------------------

www-dev:
	cd apps/www && npm install && npm run dev

www-build:
	cd apps/www && npm install && npm run build

www-docker-build:
	docker build -t ghcr.io/fapiper/fabianpiper.com/www:$(DEPLOY_VERSION) ./apps/www
	docker tag ghcr.io/fapiper/fabianpiper.com/www:$(DEPLOY_VERSION) ghcr.io/fapiper/fabianpiper.com/www:latest

#----------------------------------------------------------------
# Utilities
#----------------------------------------------------------------

encrypt:
	sops --encrypt --in-place $(SECRETS_FILE)

decrypt:
	sops --decrypt --in-place $(SECRETS_FILE)

confirm-destroy:
	@prompt=$(shell bash -c 'read -p "Are you sure you want to destroy the $(STACK) stack? Type \"yes\" to proceed: " prompt; echo $$prompt'); \
	if [ "$$prompt" != "yes" ]; then echo "Destruction aborted."; exit 1; fi

help:
	@echo "fabianpiper.com Platform Management"
	@echo ""
	@echo "Infra Targets:"
	@echo "  make bootstrap      - Run the full Atmos workflow"
	@echo "  make apply-[comp]   - Apply a specific Atmos component"
	@echo "  make destroy        - Teardown the stack"
	@echo ""
	@echo "WWW Targets:"
	@echo "  make www-dev        - Run portfolio locally"
	@echo "  make www-docker-build   - Build & tag container"
	@echo ""
	@echo "Security:"
	@echo "  make encrypt        - Encrypt secrets.yaml"
	@echo "  make decrypt        - Decrypt secrets.yaml"

endif