> [!WARNING]  
> WIP: This repository is currently undergoing some refactorings

<div align="center">

# fabianpiper.com

*Another overengineered portfolio using K3s, Terraform, Atmos, Argo CD on OCI Free Tier*

</div>

---

## Stack

* Infrastructure as Code: Terraform orchestrated by [Atmos](https://atmos.tools).
* Container Orchestration: K3s on Oracle Cloud Infrastructure (OCI).
* Ingress & Networking: Cloudflare Tunnels + Kubernetes Gateway API (Envoy).
* GitOps: Argo CD using the "App of Apps" pattern.
* Automation: Argo CD Image Updater for CD via GHCR.

---

## Overview

The infrastructure is managed following a component-based setup using [Atmos](https://atmos.tools):

* Modules: Reusable, environment-agnostic Terraform logic
* Components: Functional wrappers for specific configurations
* Stacks: Multi-environment configuration (Dev, Prod)

### Networking

A secure, private-first VCN on OCI. 
K3s control plane and workers reside in private subnets, with traffic entering through a Cloudflare Tunnel.

---

## GitOps & Delivery

The repository follows the App of Apps pattern:
1. Infrastructure Apps: Cluster-wide tools (`cert-manager`, `external-dns`, `external-secrets`, `envoy-gateway`)
2. Business Apps: The portfolio application (`www`, *more to come...*)

Continuous Delivery is automated via Argo CD Image Updater. It monitors GHCR, detects new tags, and commits the update back to this repository to trigger a rollout.

---

## Secret Management

* At Rest: Secrets are encrypted in Git using SOPS + age.
* Cloud: Sensitive values are provisioned into OCI Vault.
* Cluster: External Secrets Operator retrieves values using Instance Principals.

---

## Setup & Deployment

Deployment and management is handled via Makefile targets. 
For example:

```bash
# Provision the entire stack (Networking, IAM, Vault, K3s, ArgoCD)
# This automatically decrypts secrets for via SOPS
make bootstrap STACK=prod-fra1

# Local application development
make app-dev
```

---

## License

This project is open-source and available under the MIT License.

#### Crafted by [Fabian Piper](https://fabianpiper.com)
