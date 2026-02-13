<div align="center">

# fabianpiper.com

*Portfolio deployment using K3s, Terraform, Atmos, and ArgoCD on Oracle Cloud Free Tier*

</div>

## Overview

This repository demonstrates infrastructure automation and GitOps principles by deploying a portfolio website on Oracle Cloud Infrastructure Free Tier. The stack uses Terraform with Atmos for infrastructure orchestration, K3s for container orchestration, and ArgoCD for continuous deployment.

Key capabilities:
- Declarative infrastructure provisioning with Terraform
- GitOps workflow via ArgoCD ApplicationSets
- Automated image updates and zero-downtime deployments
- Secure secret management using SOPS and OCI Vault
- CI/CD pipeline with minimal credentials via GitHub OIDC

## Prerequisites

Install the following tools before beginning:

- [Make](https://www.gnu.org/software/make/) v4.3+
- [Terraform](https://www.terraform.io/) v1.14+
- [Atmos](https://atmos.tools) v0.23+
- [SOPS](https://github.com/mozilla/sops) v3.11+
- [age](https://github.com/FiloSottile/age) v1.3+
- [Docker](https://www.docker.com) v29.1+
- [Bun](https://bun.sh) v1.3+

## Installation

### Account Setup

1. Create Oracle Cloud Infrastructure account
2. Upgrade Free Tier to paid account for priority resource allocation (remains within Free Tier limits)
3. Create Cloudflare account and generate API token with DNS management permissions
4. Generate GitHub Personal Access Token with `repo` and `packages` scopes

### Repository Configuration

```bash
git clone https://github.com/fapiper/fabianpiper.com.git
cd fabianpiper.com
```

Initialize encryption and configure secrets:

```bash
make setup
```

> [!NOTE]
> This generates `secrets/.sops.key` and configures SOPS for all secret files.

Copy the example secrets file and add your credentials:

```bash
cp secrets/prod/secrets.example.yaml secrets/prod/secrets.decrypted.yaml
```

Edit `secrets/prod/secrets.decrypted.yaml` with your actual values, then encrypt:

```bash
make sops-encrypt-prod
```

### Infrastructure Deployment

Deploy the complete stack with a single command:

```bash
make deploy-prod
```

This provisions networking, IAM policies, OCI Vault, OIDC configuration, and a K3s cluster with ArgoCD automatically installed.

Verify deployment health:

```bash
make validate-prod
```

### Accessing ArgoCD

Retrieve the admin password:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'
```

Create a port forward to access the UI:

```bash
ssh -i ~/.ssh/id_rsa -L 8080:10.0.2.10:80 ubuntu@<INGRESS_IP>
```

Open your browser to `http://localhost:8080` and log in with username `admin` and the retrieved password.

## Architecture

The infrastructure consists of:

- VCN with public (10.0.1.0/24) and private (10.0.2.0/24) subnets
- Three ARM Ampere A1 instances running K3s
- OCI Vault for runtime secret storage
- GitHub OIDC provider for CI/CD authentication
- ArgoCD managing GitOps deployments

### Directory Structure

```
fabianpiper.com/
├── components/terraform/       # Atmos component wrappers
│   ├── networking/            # VCN, subnets, security lists
│   ├── iam/                   # Dynamic groups and policies
│   ├── vault/                 # OCI Vault and stored secrets
│   ├── oidc/                  # GitHub OIDC provider
│   └── k3s-cluster/           # K3s instances and cloud-init
├── modules/                    # Terraform module implementations
├── stacks/                     # Atmos stack configurations
│   ├── orgs/glg/prod/fra.yaml # Production deployment config
│   ├── mixins/                # Reusable configuration snippets
│   └── workflows/             # Multi-component workflows
├── kubernetes/                 # GitOps manifests
│   ├── bootstrap/             # ArgoCD installation and root app
│   │   ├── root.yaml         # Single entry point
│   │   ├── templates/        # ApplicationSets
│   │   └── argocd/           # ArgoCD manifests
│   ├── infrastructure/        # Platform services
│   └── apps/                  # Application deployments
├── apps/www/                   # Website source code
├── secrets/prod/               # SOPS-encrypted secrets
└── .github/workflows/          # CI/CD automation
```

## CI/CD Pipeline

The automated deployment flow:

1. Code changes pushed to `main` branch
2. GitHub Actions workflow triggered
3. Docker image built and pushed to GHCR
4. ArgoCD Image Updater detects new image digest
5. ArgoCD automatically syncs and deploys updated application

> [!IMPORTANT]
> Only one GitHub secret is required: `SOPS_AGE_KEY` for infrastructure modifications.

## Development

Start the local development server:

```bash
make dev-www
```

Build production bundle:

```bash
make build-www
```

Build Docker image:

```bash
make docker-build-prod-www
```

## Common Operations

### Infrastructure Management

```bash
make plan-prod-all             # Review planned changes for all components
make apply-prod-networking     # Deploy VCN and subnets
make apply-prod-iam            # Deploy IAM policies
make apply-prod-vault          # Deploy OCI Vault
make apply-prod-oidc           # Deploy OIDC provider
make apply-prod-k3s-cluster    # Deploy K3s cluster
```

### Secret Management

```bash
make sops-encrypt-prod         # Encrypt secrets before committing
make sops-decrypt-prod         # Decrypt secrets for editing
```

### Teardown

```bash
make destroy-prod-all          # Destroy all infrastructure components
```

## Documentation

For detailed operational procedures and agent-friendly instructions, refer to [AGENT.md](AGENT.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

