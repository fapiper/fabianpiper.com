#----------------------------------------------------------------
# Shell & Tooling Aliases
#----------------------------------------------------------------
SHELL      := /bin/sh
ATMOS      := atmos
TERRAFORM  := terraform
SOPS       := sops
BUN        := bun
DOCKER     := docker
FIND       := find
PRINTF     := printf
SED        := sed
GIT        := git
AGE_KEYGEN := age-keygen

#----------------------------------------------------------------
# Metadata & Versioning
#----------------------------------------------------------------
REGISTRY            := ghcr.io/fapiper/fabianpiper.com
CURRENT_BRANCH      := $(shell $(GIT) rev-parse --abbrev-ref HEAD | $(SED) 's/[^a-zA-Z0-9]/-/g')
CURRENT_COMMIT_HASH := $(shell $(GIT) rev-parse --short=10 HEAD)
DEPLOY_VERSION      := $(CURRENT_BRANCH)-$(CURRENT_COMMIT_HASH)

#----------------------------------------------------------------
# APPS
#----------------------------------------------------------------
WWW                 := www
ARGOCD              := argocd
ALL_APPS            := $(WWW) $(ARGOCD)

#----------------------------------------------------------------
# Configuration & Paths
#----------------------------------------------------------------
STACK_SUFFIX        := fra1
SOPS_SECRETS_DIR    := ./secrets
APPS_DIR            := ./apps
AGE_KEY_FILE        := $(SOPS_SECRETS_DIR)/.sops.key

#----------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------
get_parts      = $(subst -, ,$@)
total_words    = $(words $(get_parts))
get_comp       = $(if $(shell [ $(total_words) -gt 1 ] && echo true),$(lastword $(get_parts)),all)
get_env        = $(if $(shell [ $(total_words) -ge 2 ] && echo true),\
                   $(word $(shell expr $(total_words) - $(if $(filter $(total_words),2),0,1)),$(get_parts)),\
                   local)
get_stack      = $(get_env)-$(STACK_SUFFIX)

#----------------------------------------------------------------
# SOPS Recursive Injection
#----------------------------------------------------------------
export SOPS_AGE_KEY_FILE := $(AGE_KEY_FILE)
export _SOPS_EXPORTED_REQUIRED_FILES
export _SOPS_REQUIRED_FILES
export _SOPS_REMAINING_FILES
export _SOPS_PROCESSING_STARTED
export _SOPS_PROCESSING_FINISHED

ifdef _SOPS_REQUIRED_FILES
    ifndef _SOPS_PROCESSING_FINISHED
        _PROCESS_SOPS_FILES := 1
        ifndef _SOPS_PROCESSING_STARTED
            _SOPS_REMAINING_FILES = $(_SOPS_REQUIRED_FILES)
            _SOPS_PROCESSING_STARTED := 1
        endif
    else
        _SOPS_REQUIRED_FILES      :=
        _SOPS_REMAINING_FILES     :=
        _SOPS_PROCESSING_STARTED  :=
        _SOPS_PROCESSING_FINISHED :=
    endif
endif

ifndef _SOPS_EXPORTED_REQUIRED_FILES
%:
	$(eval _ENV_NAME := $(get_env))
	$(eval _SECRETS  := $(wildcard $(SOPS_SECRETS_DIR)/$(_ENV_NAME)/*.yaml))
	@# don't wrap help, setup, or targets with no secrets
	@if [ "$@" = "help" ] || [ "$@" = "sops-setup" ] || [ -z "$(_SECRETS)" ]; then \
		$(MAKE) $@ _SOPS_EXPORTED_REQUIRED_FILES=1; \
	else \
		_SOPS_EXPORTED_REQUIRED_FILES=1 _SOPS_REQUIRED_FILES="$(_SECRETS)" $(MAKE) $@; \
	fi
else ifdef _PROCESS_SOPS_FILES
%:
	$(eval _CURRENT_SOPS_FILE := $(firstword $(_SOPS_REMAINING_FILES)))
	$(eval _SOPS_REMAINING_FILES := $(wordlist 2,$(words $(_SOPS_REMAINING_FILES)),$(_SOPS_REMAINING_FILES)))
	$(if $(_SOPS_REMAINING_FILES),,$(eval _SOPS_PROCESSING_FINISHED := 1))
	@$(SOPS) exec-env $(_CURRENT_SOPS_FILE) '$(MAKE) $@'
else
%: _SOPS_EXPORTED_REQUIRED_FILES :=

#----------------------------------------------------------------
# Initial Setup
#----------------------------------------------------------------
setup: check-tools sops-setup sops-init-all

check-tools:
	@for tool in $(ATMOS) $(TERRAFORM) $(SOPS) $(BUN) $(DOCKER) $(AGE_KEYGEN) $(GIT); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			$(PRINTF) -- "Error: '$$tool' is not installed or not in PATH.\n"; \
			exit 1; \
		fi \
	done

#----------------------------------------------------------------
# Infrastructure Targets
#----------------------------------------------------------------

# make bootstrap-prod
bootstrap-%:
	$(ATMOS) workflow bootstrap -s $(get_stack)

# make plan-prod OR make plan-prod-vault
plan-%:
	@if [ "$(get_comp)" = "all" ]; then \
		$(ATMOS) workflow plan -s $(get_stack); \
	else \
		$(ATMOS) $(TERRAFORM) plan $(get_comp) -s $(get_stack); \
	fi

# make apply-prod-vault
apply-%:
	$(ATMOS) $(TERRAFORM) apply $(get_comp) -s $(get_stack)

# make validate-prod
validate-%:
	@if [ "$(get_comp)" = "all" ]; then \
		$(ATMOS) workflow validate -s $(get_stack); \
	else \
		$(ATMOS) $(TERRAFORM) validate $(get_comp) -s $(get_stack); \
	fi

# make destroy-prod-all or make destroy-prod-vcn
destroy-%: confirm-destroy
	@if [ "$(get_comp)" = "all" ]; then \
		$(ATMOS) workflow destroy -s $(get_stack); \
	else \
		$(ATMOS) $(TERRAFORM) destroy $(get_comp) -s $(get_stack); \
	fi

#----------------------------------------------------------------
# App Targets
#----------------------------------------------------------------

dev-%:
	cd $(APPS_DIR)/$(get_comp) && $(BUN) install && $(BUN) run dev

build-%:
	cd $(APPS_DIR)/$(get_comp) && $(BUN) install && $(BUN) run build

docker-build-%:
	$(DOCKER) build --secret id=secrets,src=$(SOPS_SECRETS_DIR)/$(get_env)/$(get_comp).yaml \
		-t $(REGISTRY)/$(get_comp):$(DEPLOY_VERSION) $(APPS_DIR)/$(get_comp)

docker-tag-%:
	$(DOCKER) tag $(REGISTRY)/$(get_comp):$(DEPLOY_VERSION) $(REGISTRY)/$(get_comp):latest

#----------------------------------------------------------------
# Secret Management (SOPS)
#----------------------------------------------------------------
sops-setup:
	@if [ ! -f "$(AGE_KEY_FILE)" ]; then \
		mkdir -p "$(SOPS_SECRETS_DIR)"; \
		$(AGE_KEYGEN) -o "$(AGE_KEY_FILE)"; \
	fi

sops-init-%:
	$(eval _PUB_KEY := $(shell grep 'public key' $(AGE_KEY_FILE) | cut -d' ' -f4))
	@if [ "$(get_env)" = "all" ]; then \
		for dir in $$(find $(SOPS_SECRETS_DIR) -maxdepth 1 -type d ! -path $(SOPS_SECRETS_DIR)); do \
			echo "creation_rules:" > "$$dir/.sops.yaml"; \
			echo "  - path_regex: .*\.yaml$$" >> "$$dir/.sops.yaml"; \
			echo "    age: $(_PUB_KEY)" >> "$$dir/.sops.yaml"; \
		done; \
	elif [ "$(get_comp)" = "all" ]; then \
		mkdir -p "$(SOPS_SECRETS_DIR)/$(get_env)"; \
		echo "creation_rules:" > "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
		echo "  - path_regex: .*\.yaml$$" >> "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
		echo "    age: $(_PUB_KEY)" >> "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
	else \
		mkdir -p "$(SOPS_SECRETS_DIR)/$(get_env)"; \
		echo "creation_rules:" > "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
		echo "  - path_regex: $(get_comp)\.yaml$$" >> "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
		echo "    age: $(_PUB_KEY)" >> "$(SOPS_SECRETS_DIR)/$(get_env)/.sops.yaml"; \
	fi

sops-encrypt-%:
	@if [ "$(get_comp)" = "all" ]; then \
		$(FIND) $(SOPS_SECRETS_DIR)/$(get_env) -name "*.yaml" -type f ! -name ".sops.yaml" -exec $(SOPS) --encrypt --in-place {} +; \
	else \
		$(SOPS) --encrypt --in-place $(SOPS_SECRETS_DIR)/$(get_env)/$(get_comp).yaml; \
	fi

sops-decrypt-%:
	@if [ "$(get_comp)" = "all" ]; then \
		$(FIND) $(SOPS_SECRETS_DIR)/$(get_env) -name "*.yaml" -type f ! -name ".sops.yaml" | while read file; do \
			$(SOPS) --decrypt "$$file" > "$${file%.yaml}.decrypted.yaml"; \
		done; \
	else \
		$(SOPS) --decrypt $(SOPS_SECRETS_DIR)/$(get_env)/$(get_comp).yaml > $(SOPS_SECRETS_DIR)/$(get_env)/$(get_comp).decrypted.yaml; \
	fi

#----------------------------------------------------------------
# Utilities
#----------------------------------------------------------------
confirm-destroy:
	@$(PRINTF) "Destroy $(get_comp) in $(get_env)? (yes/no): " && read prompt && [ "$$prompt" = "yes" ] || (echo "Aborted." && exit 1)

help:
	@$(PRINTF) "========================================================================\n"
	@$(PRINTF) "fabianpiper.com | Version: $(DEPLOY_VERSION)\n"
	@$(PRINTF) "========================================================================\n"
	@$(PRINTF) "INFRASTRUCTURE (Pattern: [action]-[env]-[comp/all])\n"
	@$(PRINTF) "  make bootstrap-[env]          Bootstrap full OCI+K3s stack\n"
	@$(PRINTF) "  make plan-[env]               Plan full stack (Defaults to all)\n"
	@$(PRINTF) "  make plan-[env]-[comp]        Plan specific component\n"
	@$(PRINTF) "  make apply-[env]-[comp]       Apply specific component\n"
	@$(PRINTF) "  make validate-[env]           Run full validation workflow\n"
	@$(PRINTF) "  make destroy-[env]-all        Destroy full stack via workflow\n\n"
	@$(PRINTF) "APPS (Pattern: [action]-[env]-[app] | Catalog: $(ALL_APPS))\n"
	@$(PRINTF) "  make dev-local-[app]          Run local development (Bun)\n"
	@$(PRINTF) "  make docker-build-prod-[app]  Build image with BuildKit secrets\n"
	@$(PRINTF) "  make docker-tag-prod-[app]    Tag image as latest\n\n"
	@$(PRINTF) "SECRETS (Pattern: sops-[action]-[env]-[file/all])\n"
	@$(PRINTF) "  make sops-setup               Prepare .sops.key in secrets/\n"
	@$(PRINTF) "  make sops-init-all            Initialize .sops.yaml for every env folder\n"
	@$(PRINTF) "  make sops-init-[env]          Initialize .sops.yaml for specific env folder\n"
	@$(PRINTF) "  make sops-init-[env]-[file]   Initialize .sops.yaml for specific file\n"
	@$(PRINTF) "  make sops-encrypt-[env]-all   Encrypt all secrets in env folder\n"
	@$(PRINTF) "  make sops-decrypt-[env]-[file]   Decrypt specific file for editing\n"
	@$(PRINTF) "========================================================================\n"

endif