#----------------------------------------------------------------
# Tooling & Configuration
#----------------------------------------------------------------
SHELL := bash

COMMIT_HASH := $(shell git rev-parse --short=10 HEAD 2>/dev/null || echo "dev")
BRANCH      := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/[^a-zA-Z0-9]/-/g' || echo "local")
VERSION     := $(BRANCH)-$(COMMIT_HASH)

SCRIPTS := ./scripts

.DEFAULT_GOAL := help
.PHONY: help setup dev build deploy-% plan-% apply-% validate-% destroy-% sops-%

#----------------------------------------------------------------
# Context Helpers
#----------------------------------------------------------------
get_stem = $(subst -, ,$*)
get_env  = $(word 1,$(get_stem))
get_app  = $(if $(word 2,$(get_stem)),$(lastword $(get_stem)),all)

# Inject secrets for <env>, then delegate to atmos.sh
run_atmos = $(SCRIPTS)/with-secrets.sh $(get_env) $(SCRIPTS)/atmos.sh
# ENV APP pair forwarded to atmos.sh for all standard targets
env_app   = $(get_env) $(get_app)
# Install deps and run a bun script in the matching app directory
bun_app   = cd $(CURDIR)/apps/$(get_app) && bun install && bun run

#----------------------------------------------------------------
# Targets
#----------------------------------------------------------------

## setup: validate tools and initialize SOPS
setup:
	@$(SCRIPTS)/setup.sh

## deploy-[env]: deploy all infrastructure
deploy-%:
	@$(run_atmos) bootstrap $(get_env) all

## plan-[env]-[comp/all]: terraform plan
plan-%:
	@$(run_atmos) plan $(env_app)

## apply-[env]-[comp]: terraform apply
apply-%:
	@$(run_atmos) apply $(env_app)

## validate-[env]-[comp/all]: static analysis
validate-%:
	@$(run_atmos) validate $(env_app)

## destroy-[env]-[comp]: infrastructure destruction
destroy-%:
	@$(run_atmos) destroy $(env_app)

## dev-[comp]: start local development
dev-%:
	@$(bun_app) dev

## build-[comp]: build production bundle locally
build-%:
	@$(bun_app) build

## sops-setup: generate age key
sops-setup:
	@$(SCRIPTS)/sops.sh setup

## sops-init-[env]: create sops config
sops-init-%:
	@$(SCRIPTS)/sops.sh init $*

## sops-encrypt-[env]: encrypt files
sops-encrypt-%:
	@$(SCRIPTS)/sops.sh encrypt $*

## sops-decrypt-[env]: decrypt files
sops-decrypt-%:
	@$(SCRIPTS)/sops.sh decrypt $*

## help: show this menu
help:
	@printf -- "========================================================================\n"
	@printf -- " fabianpiper.com | Version: $(VERSION)\n"
	@printf -- "========================================================================\n"
	@grep -E '^## .*' $(MAKEFILE_LIST) | sed 's/## //' | awk -F': ' '{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf -- "========================================================================\n"
