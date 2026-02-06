#----------------------------------------------------------------
# Tooling & Metadata
#----------------------------------------------------------------
SHELL      := /bin/sh
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

SECRETS_DIR   := ./secrets
AGE_KEY_FILE  := $(SECRETS_DIR)/.sops.key
SOPS_CONFIG   := .sops.yaml

.DEFAULT_GOAL := help
.PHONY: setup check-tools sops-setup help

#----------------------------------------------------------------
# Context Helpers
#----------------------------------------------------------------
parse_stem = $(subst -, ,$*)
get_env    = $(word 1,$(parse_stem))
get_comp   = $(if $(word 2,$(parse_stem)),$(lastword $(parse_stem)),all)
get_stack  = $(get_env)-fra1

#----------------------------------------------------------------
# SOPS Recursive Injection Wrapper
#----------------------------------------------------------------
export SOPS_AGE_KEY_FILE := $(AGE_KEY_FILE)
export _SOPS_FILES
export _SOPS_READY

ifndef _SOPS_READY
%:
	$(eval _WRAPPER_PARTS := $(subst -, ,$@))
	$(eval _WRAPPER_LEN   := $(words $(_WRAPPER_PARTS)))
	$(eval _ENV_IDX       := $(if $(filter 2,$(_WRAPPER_LEN)),2,$(shell expr $(_WRAPPER_LEN) - 1)))
	$(eval _ENV           := $(if $(shell [ $(_WRAPPER_LEN) -gt 1 ] && echo true),$(word $(_ENV_IDX),$(_WRAPPER_PARTS)),))
	$(eval _SECRETS       := $(filter-out %.example.yaml %.decrypted.yaml, $(wildcard $(SECRETS_DIR)/$(_ENV)/*.yaml)))
	@if echo "$@" | grep -qE "^(help|setup|check|sops-)" || [ -z "$(_SECRETS)" ]; then \
		$(MAKE) $@ _SOPS_READY=1; \
	else \
		_SOPS_READY=1 _SOPS_FILES="$(_SECRETS)" $(MAKE) $@; \
	fi
else ifneq ($(_SOPS_READY),done)
%:
	@FILE=$(firstword $(_SOPS_FILES)); \
	REMAINING="$(wordlist 2,$(words $(_SOPS_FILES)),$(_SOPS_FILES))"; \
	if [ -z "$$FILE" ]; then \
		$(MAKE) $@ _SOPS_READY=done; \
	else \
		$(SOPS) exec-env "$$FILE" "$(MAKE) $@ _SOPS_READY=1 _SOPS_FILES='$$REMAINING'"; \
	fi
else
%: _SOPS_READY :=
endif # _SOPS_READY

#----------------------------------------------------------------
# Targets (Secrets, Apps, Infra)
#----------------------------------------------------------------

## setup: validate installation and initialize local age keys
setup: check-tools sops-setup sops-init-all

check-tools:
	@for tool in $(ATMOS) terraform $(SOPS) $(BUN) $(DOCKER) $(AGE_KEYGEN) git; do \
		command -v $$tool >/dev/null 2>&1 || { $(PRINTF) -- "Error: $$tool missing\n"; exit 1; }; \
	done

## bootstrap-[env]: initialize the oci/k3s stack via atmos workflow
bootstrap-%:
	$(ATMOS) workflow bootstrap -s $(get_stack)

## plan-[env]-[comp/all]: generate terraform plan for a component or full stack
plan-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow plan -s $(get_stack); \
	else $(ATMOS) terraform plan $(get_comp) -s $(get_stack); fi

## apply-[env]-[comp]: deploy a specific terraform component to an environment
apply-%:
	$(ATMOS) terraform apply $(get_comp) -s $(get_stack)

## validate-[env]-[comp/all]: run static analysis and linting on the stack
validate-%:
	@if [ "$(get_comp)" = "all" ]; then $(ATMOS) workflow validate -s $(get_stack); \
	else $(ATMOS) terraform validate $(get_comp) -s $(get_stack); fi

## destroy-[env]-[comp]: interactive destruction of infrastructure with confirmation
destroy-%:
	@$(PRINTF) -- "Destroy $(get_comp) in $(get_env)? (yes/no): " && read prompt && [ "$$prompt" = "yes" ] || exit 1
	@$(MAKE) _destroy-$*

# Internal target for non-interactive destruction (no help comment)
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

## sops-setup: generate master age private key if it does not exist
sops-setup:
	@mkdir -p $(SECRETS_DIR)
	@if [ ! -f "$(AGE_KEY_FILE)" ]; then $(AGE_KEYGEN) -o "$(AGE_KEY_FILE)"; fi

## sops-init-[env]: create .sops.yaml config with age public key for an environment
sops-init-%:
	$(eval PK := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@if [ "$(get_env)" = "all" ]; then \
		for d in $$(ls -d $(SECRETS_DIR)/*/ 2>/dev/null); do \
			$(PRINTF) "creation_rules:\n  - path_regex: .*\.yaml$$\n    age: $(PK)\n" | cat > "$$d$(SOPS_CONFIG)"; \
		done; \
	else \
		mkdir -p $(SECRETS_DIR)/$(get_env); \
		$(PRINTF) "creation_rules:\n  - path_regex: .*\.yaml$$\n    age: $(PK)\n" > "$(SECRETS_DIR)/$(get_env)/$(SOPS_CONFIG)"; \
	fi

## sops-encrypt-[env]-[comp/all]: encrypt .decrypted.yaml files into .yaml using age
sops-encrypt-%:
	$(eval PK := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@FILES=$(if $(filter all,$(get_comp)),"$$(ls $(SECRETS_DIR)/$(get_env)/*.decrypted.yaml 2>/dev/null)","$(SECRETS_DIR)/$(get_env)/$(get_comp).decrypted.yaml"); \
	for f in $$FILES; do \
		set -e; $(SOPS) --encrypt --age $(PK) --output "$${f%.decrypted.yaml}.yaml" "$$f"; \
	done

## sops-decrypt-[env]-[comp/all]: decrypt .yaml files into .decrypted.yaml for editing
sops-decrypt-%:
	@FILES=$(if $(filter all,$(get_comp)),"$$(ls $(SECRETS_DIR)/$(get_env)/*.yaml 2>/dev/null | grep -v $(SOPS_CONFIG))","$(SECRETS_DIR)/$(get_env)/$(get_comp).yaml"); \
	for f in $$FILES; do \
		set -eo pipefail; $(SOPS) --decrypt "$$f" | cat > "$${f%.yaml}.decrypted.yaml"; \
	done

#----------------------------------------------------------------
# Docs
#----------------------------------------------------------------

## help: show this command menu with detailed target descriptions
help:
	@$(PRINTF) -- "========================================================================\n"
	@$(PRINTF) -- " fabianpiper.com | Version: $(DEPLOY_VER)\n"
	@$(PRINTF) -- "========================================================================\n"
	@grep -E '^## .*' $(MAKEFILE_LIST) | sed 's/## //' | awk -F': ' '{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@$(PRINTF) -- "========================================================================\n"