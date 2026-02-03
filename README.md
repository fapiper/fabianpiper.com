> [!WARNING]  
> WIP: This repository is currently undergoing some refactorings

<div align="center">

# fabianpiper.com

*Another overengineered portfolio using K3s, Terraform, Atmos, Argo CD on OCI Free Tier*

</div>

---

## Getting Started

### Prerequisites
- [Make (v4.3+)](https://www.gnu.org/software/make/)
- [Terraform (v1.14+)](https://www.terraform.io/)
- [Atmos (v0.23+)](https://atmos.tools) 
- [SOPS (v3.11+)](https://github.com/mozilla/sops)
- [age (v1.3+)](https://github.com/FiloSottile/age)
- [Docker (v29.1+)](https://www.docker.com)
- [Bun (v1.3+)](https://bun.sh)

### Installation
1. Create Oracle Cloud Infrastructure account
2. Upgrade Free Tier account to a paid account. Paid accounts precede Free Tier accounts when it comes to resources (especially instances) provisioning by OCI. The resources used in this repository fit within the Free Tier limits
3. [Optional] Create budgets to control costs
4. Create a Cloudflare account and API token with appropriate permissions for DNS management
5. Create a GitHub Personal Access Token with `repo` and `workflow` scopes
6. Clone the repo
```bash
git clone https://github.com/fapiper/fabianpiper.com.git
```
7. Install the [Prerequisites](#prerequisites)
8. Modify the `secrets/` files to add your OCI credentials, Cloudflare API token, and GitHub PAT
9. Follow the [Quick Start](#quick-start) steps

### Quick Start

Follow these steps to get started with the repository.

#### Setup
Validate the local environment, initialize the project, and set up secrets.
```bash
make setup
```

#### Provisioning
Create an entire OCI stack (Networking, IAM, Vault, K3s) in one command

```bash
make bootstrap-prod
# Verify the health of all components
make validate-prod
```

#### Application Development
Build and tag your applications for deployment

```bash
# Run the website in ./apps/www locally
make dev-local-www

# Build the website's Docker image
make docker-build-prod-www
```

## Stack

* Infrastructure as Code: [Terraform](https://www.terraform.io/) + [Atmos](https://atmos.tools).
* Container Orchestration: K3s on Oracle Cloud Infrastructure (OCI).
* Ingress & Networking: Cloudflare Tunnels + Kubernetes Gateway API (Envoy).
* GitOps: Argo CD using the "App of Apps" pattern.
* Automation: Argo CD Image Updater for CD via GHCR.

## Overview

The infrastructure is managed following a component-based setup using Atmos:

* Modules: Reusable, environment-agnostic Terraform logic
* Components: Functional wrappers for specific configurations
* Stacks: Multi-environment configuration (Dev, Prod)

### Networking

A secure, private-first VCN on OCI. 
K3s control plane and workers reside in private subnets, with traffic entering through a Cloudflare Tunnel.

## GitOps & Delivery

The repository follows the App of Apps pattern:
1. Infrastructure Apps: Cluster-wide tools (`cert-manager`, `external-dns`, `external-secrets`, `envoy-gateway`)
2. Business Apps: The portfolio application (`www`, *more to come...*)

Continuous Delivery is automated via Argo CD Image Updater. It monitors GHCR, detects new tags, and commits the update back to this repository to trigger a rollout.

## Secret Management

* At Rest: Secrets are encrypted in Git using SOPS + age.
* Cloud: Sensitive values are provisioned into OCI Vault.
* Cluster: External Secrets Operator retrieves values using Instance Principals.

## License

This project is open-source and available under the MIT License.