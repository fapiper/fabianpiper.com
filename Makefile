#----------------------------------------------------------------
# Tooling & Metadata
#----------------------------------------------------------------
SHELL      := /bin/bash
BUN        := bun
DOCKER     := docker
SOPS       := sops
ATMOS      := atmos
AGE_KEYGEN := age-keygen
PRINTF     := printf

REGISTRY      := ghcr.io/fapiper/fabianpiper.com
COMMIT_HASH   := $(shell git rev-parse --short=10 HEAD 2>/dev/null || echo "dev")
BRANCH        := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/[^a-zA-Z0-9]/-/g' || echo "local")
DEPLOY_VER    := $(BRANCH)-$(COMMIT_HASH)

SECRETS_DIR   := ./secrets/prod
AGE_KEY_FILE  := ./secrets/.sops.key
SOPS_CONFIG   := .sops.yaml
SCRIPTS_DIR   := ./scripts

.DEFAULT_GOAL := help
.PHONY: setup check-tools sops-setup help init

#----------------------------------------------------------------
# Context Helpers
#----------------------------------------------------------------
parse_stem = $(subst -, ,$*)
get_env    = $(word 1,$(parse_stem))
get_comp   = $(if $(word 2,$(parse_stem)),$(lastword $(parse_stem)),all)
get_stack  = glg-$(get_env)-fra

#----------------------------------------------------------------
# SOPS Recursive Injection
#----------------------------------------------------------------
export SOPS_AGE_KEY_FILE := $(AGE_KEY_FILE)
export _SOPS_FILES
export _SOPS_READY

ifndef _SOPS_READY
%:
	@SECRETS_FILE="$(SECRETS_DIR)/secrets.yaml"; \
	if echo "$@" | grep -qE "^(help|setup|check|sops-|init)" || [ ! -f "$$SECRETS_FILE" ]; then \
		$(MAKE) $@ _SOPS_READY=1; \
	else \
		$(SOPS) exec-env "$$SECRETS_FILE" "$(MAKE) $@ _SOPS_READY=1"; \
	fi
else

#----------------------------------------------------------------
# Targets (Setup, Secrets, Infra, Apps)
#----------------------------------------------------------------

## setup: validate tools and initialize SOPS encryption
setup: check-tools sops-setup sops-init-prod

check-tools:
	@for tool in $(ATMOS) terraform $(SOPS) $(AGE_KEYGEN); do \
		command -v $$tool >/dev/null 2>&1 || { $(PRINTF) -- "$$tool not found (required)\n"; exit 1; }; \
	done
	@$(PRINTF) -- "✓ All required tools are installed\n"

## deploy-[env]: deploy all infrastructure components
deploy-%:
	@$(ATMOS) workflow bootstrap -s $(get_stack)

## plan-[env]-[comp/all]: generate terraform plan for a component or full stack
plan-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow plan -s $(get_stack); \
	else $(ATMOS) terraform plan $(get_comp) -s $(get_stack); fi

## apply-[env]-[comp]: deploy a specific terraform component to an environment
apply-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow apply -s $(get_stack); \
	else $(ATMOS) terraform apply $(get_comp) -s $(get_stack); fi

## validate-[env]-[comp/all]: run static analysis and linting on the stack
validate-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow validate -s $(get_stack); \
	else $(ATMOS) terraform validate $(get_comp) -s $(get_stack); fi

## destroy-[env]-[comp]: destruction of infrastructure
destroy-%:
	@$(PRINTF) -- "Destroy $(get_comp) in $(get_env)? (yes/no): " && read prompt && [ "$$prompt" = "yes" ] || exit 1
	@$(MAKE) _destroy-$*

# Internal target for non-interactive destruction
_destroy-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow destroy -s $(get_stack); \
	else $(ATMOS) terraform destroy $(get_comp) -s $(get_stack) -auto-approve; fi

## dev-[comp]: start local development environment for an app using bun
dev-%:
	cd apps/$(get_comp) && $(BUN) install && $(BUN) run dev

## build-[comp]: build the production bundle for a specific app
build-%:
	cd apps/$(get_comp) && $(BUN) install && $(BUN) run build

## docker-build-[env]-[comp]: build docker image
docker-build-%:
	$(DOCKER) build --secret id=secrets,src=$(SECRETS_DIR)/$(get_env)/$(get_comp).yaml \
		-t $(REGISTRY)/$(get_comp):$(DEPLOY_VER) apps/$(get_comp)

## docker-tag-[comp]: alias the current deploy version to latest
docker-tag-%:
	$(DOCKER) tag $(REGISTRY)/$(get_comp):$(DEPLOY_VER) $(REGISTRY)/$(get_comp):latest

## vault-import-secrets-[app]: fetch secrets from OCI vault and generate .env
vault-import-secrets-%:
	@oci vault secret list --compartment-id $(TF_VAR_compartment_ocid) --name-contains "$*" \
		--query 'data[*].{name:name, id:id}' --output json > .tmp_ids.json
	@jq -c '.[]' .tmp_ids.json | while read i; do \
		NAME=$$(echo $$i | jq -r '.name'); \
		ID=$$(echo $$i | jq -r '.id'); \
		VALUE=$$(oci secrets secret-bundle get --secret-id $$ID --query 'data."secret-bundle-content".content' --raw | base64 -d); \
		echo "$${NAME#$*_}=$$VALUE" >> apps/$*/.env; \
	done
	@rm .tmp_ids.json

## sops-setup: generate master age private key if it does not exist
sops-setup:
	@mkdir -p $(SECRETS_DIR)
	@if [ ! -f "$(AGE_KEY_FILE)" ]; then \
		$(AGE_KEYGEN) -o "$(AGE_KEY_FILE)"; \
		$(PRINTF) -- "Age key generated at $(AGE_KEY_FILE)\n"; \
	else \
		$(PRINTF) -- "Age key already exists\n"; \
	fi

## sops-init-prod: create .sops.yaml config with age public key
sops-init-prod:
	$(eval PK := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@mkdir -p $(SECRETS_DIR)
	@$(PRINTF) "creation_rules:\n  - path_regex: .*\\.yaml$$\n    age: $(PK)\n" > "$(SECRETS_DIR)/$(SOPS_CONFIG)"
	@$(PRINTF) -- "SOPS configuration created\n"

## sops-encrypt-prod: encrypt secrets.decrypted.yaml into secrets.yaml
sops-encrypt-prod:
	$(eval PK := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@if [ ! -f "$(SECRETS_DIR)/secrets.decrypted.yaml" ]; then \
		$(PRINTF) -- "$(SECRETS_DIR)/secrets.decrypted.yaml not found\n"; \
		$(PRINTF) -- "   Run 'make init' first\n"; \
		exit 1; \
	fi
	@$(SOPS) --encrypt --age $(PK) --output "$(SECRETS_DIR)/secrets.yaml" "$(SECRETS_DIR)/secrets.decrypted.yaml"
	@$(PRINTF) -- "Secrets encrypted to $(SECRETS_DIR)/secrets.yaml\n"

## sops-decrypt-prod: decrypt secrets.yaml into secrets.decrypted.yaml for editing
sops-decrypt-prod:
	@if [ ! -f "$(SECRETS_DIR)/secrets.yaml" ]; then \
		$(PRINTF) -- "$(SECRETS_DIR)/secrets.yaml not found\n"; \
		exit 1; \
	fi
	@$(SOPS) --decrypt "$(SECRETS_DIR)/secrets.yaml" > "$(SECRETS_DIR)/secrets.decrypted.yaml"
	@$(PRINTF) -- "Secrets decrypted to $(SECRETS_DIR)/secrets.decrypted.yaml\n"
%: _SOPS_READY :=
endif # _SOPS_READY

#----------------------------------------------------------------
# Docs
#----------------------------------------------------------------

## help: show this menu with target descriptions
help:
	@$(PRINTF) -- "========================================================================\n"
	@$(PRINTF) -- " fabianpiper.com | Version: $(DEPLOY_VER)\n"
	@$(PRINTF) -- "========================================================================\n"
	@grep -E '^## .*' $(MAKEFILE_LIST) | sed 's/## //' | awk -F': ' '{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@$(PRINTF) -- "========================================================================\n"