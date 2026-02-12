#----------------------------------------------------------------
# Tooling & Configuration
#----------------------------------------------------------------
SHELL         := /bin/bash
BUN           := bun
DOCKER        := docker
SOPS          := sops
ATMOS         := atmos
AGE_KEYGEN    := age-keygen
PRINTF        := printf

# Metadata
REGISTRY      := ghcr.io/fapiper/fabianpiper.com
COMMIT_HASH   := $(shell git rev-parse --short=10 HEAD 2>/dev/null || echo "dev")
BRANCH        := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/[^a-zA-Z0-9]/-/g' || echo "local")
DEPLOY_VER    := $(BRANCH)-$(COMMIT_HASH)

# Paths & Files
SECRETS_DIR   := ./secrets
AGE_KEY_FILE  := $(SECRETS_DIR)/.sops.key
SOPS_CONFIG   := .sops.yaml

# Configuration
# Patterns to exclude from secret injection
SOPS_EXCLUDES      := %.decrypted.yaml %$(SOPS_CONFIG) %.example.yaml
# Targets that do not require secrets
NO_SECRETS_TARGETS := help setup check-tools sops-% init

.DEFAULT_GOAL := help
.PHONY: setup check-tools sops-setup help init debug-env

#----------------------------------------------------------------
# Context Helpers
#----------------------------------------------------------------
get_stem  = $(subst -, ,$*)
get_env   = $(word 1,$(get_stem))
get_app   = $(if $(word 2,$(get_stem)),$(lastword $(get_stem)),all)
get_stack = glg-$(get_env)-fra

#----------------------------------------------------------------
# SOPS Injection (Index-Based Recursion)
#----------------------------------------------------------------
export SOPS_AGE_KEY_FILE := $(AGE_KEY_FILE)

# Detect environment from target (default to prod)
ENV_MATCH   := $(shell echo "$(firstword $(MAKECMDGOALS))" | grep -oE '(prod|dev|staging)' || echo "prod")
SECRETS_LIST := $(sort $(filter-out $(SOPS_EXCLUDES), $(wildcard $(SECRETS_DIR)/$(ENV_MATCH)/*.yaml)))
SECRETS_LEN  := $(words $(SECRETS_LIST))

ifndef SOPS_IDX
SOPS_IDX := 0
endif

# Init (Index 0)
ifeq ($(SOPS_IDX), 0)
%:
	@if echo "$@" | grep -qE "^($(subst $(space),|,$(NO_SECRETS_TARGETS)))"; then \
	    $(MAKE) --no-print-directory $@ SOPS_IDX=1; \
	else \
	    $(MAKE) --no-print-directory $@ SOPS_IDX=1; \
	fi

# Recursion (Index 1..N)
else ifneq ($(shell test $(SOPS_IDX) -le $(SECRETS_LEN) && echo yes),)
%:
	$(eval CURRENT_FILE := $(word $(SOPS_IDX), $(SECRETS_LIST)))
	$(eval NEXT_IDX     := $(shell expr $(SOPS_IDX) + 1))
	@if [ -f "$(CURRENT_FILE)" ]; then \
	    $(SOPS) exec-env "$(CURRENT_FILE)" "$(MAKE) --no-print-directory $@ SOPS_IDX=$(NEXT_IDX)"; \
	else \
	    $(MAKE) --no-print-directory $@ SOPS_IDX=$(NEXT_IDX); \
	fi

# Execution (Index > N)
else

#----------------------------------------------------------------
# Targets
#----------------------------------------------------------------

## setup: validate tools and initialize SOPS
setup: check-tools sops-setup sops-init-prod

check-tools:
	@for tool in $(ATMOS) terraform $(SOPS) $(AGE_KEYGEN); do \
	   command -v $$tool >/dev/null 2>&1 || { $(PRINTF) -- "$$tool not found\n"; exit 1; }; \
	done

## deploy-[env]: deploy all infrastructure
deploy-%:
	@$(ATMOS) workflow bootstrap -s $(get_stack)

## plan-[env]-[comp/all]: terraform plan
plan-%:
	@if [ "$(get_app)" = "all" ]; then $(ATMOS) workflow plan -s $(get_stack); \
	else $(ATMOS) terraform plan $(get_app) -s $(get_stack); fi

## apply-[env]-[comp]: terraform apply
apply-%:
	@if [ "$(get_app)" = "all" ]; then $(ATMOS) workflow apply -s $(get_stack); \
	else $(ATMOS) terraform apply $(get_app) -s $(get_stack); fi

## validate-[env]-[comp/all]: static analysis
validate-%:
	@if [ "$(get_app)" = "all" ]; then $(ATMOS) workflow validate -s $(get_stack); \
	else $(ATMOS) terraform validate $(get_app) -s $(get_stack); fi

## destroy-[env]-[comp]: infrastructure destruction
destroy-%:
	@$(PRINTF) -- "Destroy $(get_app) in $(get_env)? (yes/no): " && read prompt && [ "$$prompt" = "yes" ] || exit 1
	@$(MAKE) _destroy-$*

_destroy-%:
	@if [ "$(get_app)" = "all" ]; then $(ATMOS) workflow destroy -s $(get_stack); \
	else $(ATMOS) terraform destroy $(get_app) -s $(get_stack) -auto-approve; fi

## dev-[comp]: start local development
dev-%:
	cd apps/$(get_app) && $(BUN) install && $(BUN) run dev

## build-[comp]: build production bundle
build-%:
	cd apps/$(get_app) && $(BUN) install && $(BUN) run build

## docker-build-[env]-[comp]: build image with secrets
docker-build-%:
	$(DOCKER) build --secret id=secrets,src=$(SECRETS_DIR)/$(get_env)/$(get_app).yaml \
	   -t $(REGISTRY)/$(get_app):$(DEPLOY_VER) apps/$(get_app)

## docker-tag-[comp]: tag as latest
docker-tag-%:
	$(DOCKER) tag $(REGISTRY)/$(get_app):$(DEPLOY_VER) $(REGISTRY)/$(get_app):latest

## vault-import-secrets-[app]: oci vault sync
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

## sops-setup: generate age key
sops-setup:
	@mkdir -p $(SECRETS_DIR)
	@test -f "$(AGE_KEY_FILE)" && echo "Age key exists" || $(AGE_KEYGEN) -o "$(AGE_KEY_FILE)"

## sops-init-prod: create sops config
sops-init-prod:
	$(eval PK := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@mkdir -p $(SECRETS_DIR)/prod
	@$(PRINTF) "creation_rules:\n  - path_regex: .*\\.yaml$$\n    age: $(PK)\n" > "$(SECRETS_DIR)/prod/$(SOPS_CONFIG)"

## sops-encrypt-prod: encrypt files
sops-encrypt-prod:
	@PK=$$(grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4); \
	for f in $(SECRETS_DIR)/prod/*.decrypted.yaml; do \
	   [ -f "$$f" ] || continue; \
	   $(SOPS) --encrypt --age "$$PK" --output "$${f%.decrypted.yaml}.yaml" "$$f"; \
	done

## sops-decrypt-prod: decrypt files
sops-decrypt-prod:
	@for f in $(SECRETS_DIR)/prod/*.yaml; do \
	   [ -f "$$f" ] || continue; \
	   [[ "$$f" == *".decrypted.yaml" || "$$f" == *"$(SOPS_CONFIG)" ]] && continue; \
	   $(SOPS) --decrypt "$$f" > "$${f%.yaml}.decrypted.yaml"; \
	done

endif

## help: show this menu
help:
	@$(PRINTF) -- "========================================================================\n"
	@$(PRINTF) -- " fabianpiper.com | Version: $(DEPLOY_VER)\n"
	@$(PRINTF) -- "========================================================================\n"
	@grep -E '^## .*' $(MAKEFILE_LIST) | sed 's/## //' | awk -F': ' '{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@$(PRINTF) -- "========================================================================\n"