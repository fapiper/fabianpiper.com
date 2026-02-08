> [!WARNING]  
> WIP: This repository is currently undergoing some refactorings

<div align="center">

# fabianpiper.com

*A portfolio using K3s, Terraform, Atmos, Argo CD on OCI Free Tier*

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
8. Copy the example secret file and fill in your values
```bash
cp secrets/prod/secrets.example.yaml secrets/prod/secrets.decrypted.yaml
# Edit secrets/prod/secrets.decrypted.yaml with your actual values
```
9. Encrypt your secrets before committing
```bash
make sops-encrypt-prod
```
10. Follow the [Quick Start](#quick-start) steps

### Quick Start

Follow these steps to get started with the repository.

#### Setup
Validate the local environment, generate the age encryption key, and initialize SOPS config for all secret files.
```bash
make setup
```

> [!NOTE]
> This generates `secrets/.sops.key` and `.sops.yaml` config. To encrypt or decrypt secrets, use `make sops-encrypt-prod` / `make sops-decrypt-prod`.

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

## Structure

```
secrets/prod/               # SOPS-encrypted secrets
stacks/prod-fra.yaml        # Main stack configuration
components/terraform/       # Infrastructure components
  ├── networking/          # VCN + subnets
  ├── iam/                 # IAM policies  
  ├── vault/               # OCI Vault
  ├── k3s-cluster/         # 3 ARM instances
  └── argocd-bootstrap/    # ArgoCD Helm deployment
argocd/                     # GitOps applications
  └── apps/                # Application definitions
apps/www/                   # Website source code
```

## Commands

```bash
make plan-prod-all                     # Plan all components
make apply-prod-networking             # Deploy network
make apply-prod-iam                    # Deploy IAM policies
make apply-prod-vault                  # Deploy OCI Vault
make apply-prod-k3s-cluster            # Deploy K3s cluster
make apply-prod-argocd-bootstrap       # Deploy ArgoCD

make sops-encrypt-prod                 # Encrypt secrets
make sops-decrypt-prod                 # Decrypt secrets for editing

make dev-www                           # Start local dev server
make build-www                         # Build production bundle
```

## License

This project is open-source and available under the MIT License.