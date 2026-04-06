# fabianpiper.com | Agent Operations Manual

Last Updated: 2026-04-06
Generated for: AI Agents
Repository: https://github.com/fapiper/fabianpiper.com
Validation Status: Docs reviewed, Code cross-referenced, Ready for autonomous operation

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Directory Structure](#3-directory-structure)
4. [Infrastructure Components](#4-infrastructure-components)
5. [Setup & Deployment](#5-setup--deployment)
6. [Code Style & Conventions](#6-code-style--conventions)
7. [Development Workflow](#7-development-workflow)
8. [Observability](#8-observability)
9. [Testing](#9-testing)
10. [Constraints & Limits](#10-constraints--limits)
11. [Troubleshooting](#11-troubleshooting)
12. [Emergency Procedures](#12-emergency-procedures)
13. [Maintenance](#13-maintenance)
14. [Agent Completion Checklist](#14-agent-completion-checklist)
15. [Reference Links](#15-reference-links)

---

## 1. Project Overview

### Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| IaC | Terraform + Atmos | >= 1.5 / >= 0.23 |
| Cloud | Oracle Cloud Infrastructure (OCI) Free Tier | eu-frankfurt-1 |
| Orchestration | K3s (lightweight Kubernetes) | latest stable |
| Application | Astro (portfolio website) | v5.7+ |
| GitOps | ArgoCD + ApplicationSets | stable |
| CI/CD | GitHub Actions | — |
| Secret Mgmt (dev) | SOPS + age | >= 3.11 / >= 1.3 |
| Secret Mgmt (runtime) | OCI Vault + Instance Principal | — |
| Secret Mgmt (CI/CD) | SOPS-decrypted OCI creds | — |
| State Backend | Local Terraform state per-component workspace | — |
| Container Registry | GitHub Container Registry (ghcr.io) | — |
| Ingress | Envoy Gateway (Gateway API) | — |
| DNS | Cloudflare via external-dns | — |
| Observability | Prometheus + Grafana | v3.3.0 / v11.6.0 |

### Architecture Mental Model

```
GitHub Push → GitHub Actions (build image, push to ghcr.io)
                    ↓
ArgoCD Image Updater (resolves digest of :latest, writes sha256 to git)
                    ↓
ArgoCD (polls git every 30s, syncs K8s manifests)
                    ↓
K3s cluster (3 ARM nodes on OCI)
  ├─ Ingress node  → Envoy Gateway (hostNetwork, NodePort 80/443)
  ├─ Server node   → K3s control plane + all infra pods
  └─ Worker node   → App pods (www)

Terraform → OCI (VCN, compute, vault, IAM)
SOPS+age  → secrets at rest in git
OCI Vault → secrets at runtime (Instance Principal, no API keys on nodes)
```

---

## 2. Architecture

### Cluster Topology

| Node | Role | Private IP | OCPUs | RAM | Public |
|------|------|-----------|-------|-----|--------|
| ingress | NAT gateway + Envoy Gateway | 10.0.1.10 | 1 | 6 GB | Yes (reserved IP) |
| server | K3s server (control plane + infra pods) | 10.0.2.10 | 2 | 12 GB | No |
| worker | K3s agent (app pods) | DHCP (10.0.2.x) | 1 | 6 GB | No |

### Networking

- **VCN CIDR**: `10.0.0.0/16` — **do not change** (subnet math depends on it)
- **Public subnet**: `10.0.1.0/24` (ingress node only)
- **Private subnet**: `10.0.2.0/24` (server + worker)
- **Pod networking**: Flannel VXLAN over UDP `8472` (must be open in OCI security lists)
- **Ingress flow**: Internet → OCI public IP → ingress:80/443 → iptables DNAT → Envoy Gateway pod (hostNetwork) → K8s Service → Pod

### ArgoCD Bootstrap Chain

```
cloud-init (server node)
  └─ kubectl apply kubernetes/bootstrap/root.yaml
       └─ ArgoCD Application "root"
            └─ watches kubernetes/bootstrap/templates/*.yaml
                 ├─ ApplicationSet "infrastructure" (discovers kubernetes/infrastructure/*)
                 ├─ ApplicationSet "apps"           (discovers kubernetes/apps/*, excludes www)
                 └─ Application    "www"            (dedicated, with Image Updater annotations)
```

Git polling interval: **30 seconds** (`requeueAfterSeconds: 30` in both ApplicationSets).

### Sync Wave Ordering Convention

ArgoCD sync waves within each Application (lower = earlier):

| Wave | Typical Resources |
|------|------------------|
| `0` | Helm operators (cert-manager, external-secrets via HelmChart CRD) |
| `5` | RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding), ConfigMaps |
| `10` | PVCs + Deployments (must be **same wave** for WaitForFirstConsumer), Services |
| `12–15` | Gateway, GatewayClass, provisioned ConfigMaps needed by later waves |
| `20` | Deployments that depend on earlier waves (e.g., Grafana needs PVC + datasource CM) |
| `25` | HTTPRoutes, Certificates |

> **K3s WaitForFirstConsumer gotcha**: `local-path` StorageClass uses `WaitForFirstConsumer` binding.
> If a PVC is in wave N and its Deployment is in wave N+1, ArgoCD waits for the PVC to become `Bound`
> before starting wave N+1 — but the PVC never binds until a Pod requests it → **deadlock**.
> **Fix: always assign PVC and its Deployment the same sync wave.**

---

## 3. Directory Structure

```
fabianpiper.com/
├── .github/workflows/
│   └── build-and-push.yaml       # Builds multi-arch (amd64+arm64) images on push to apps/
├── apps/
│   └── www/                      # Astro 5.7 portfolio site
│       ├── Dockerfile
│       ├── package.json
│       └── src/
├── kubernetes/
│   ├── bootstrap/
│   │   ├── root.yaml             # Single ArgoCD Application (applied via cloud-init)
│   │   └── templates/
│   │       ├── infrastructure.yaml  # ApplicationSet → kubernetes/infrastructure/*
│   │       ├── apps.yaml            # ApplicationSet → kubernetes/apps/* (excludes www)
│   │       └── www.yaml             # Dedicated Application for www (Image Updater annotations)
│   ├── apps/
│   │   └── www/                  # Portfolio – Helm chart (Chart.yaml + values.yaml + templates/)
│   └── infrastructure/
│       ├── argocd-image-updater/   # Auto-updates image digest, git write-back   [Kustomize]
│       ├── cert-manager/           # TLS via Let's Encrypt (K3s HelmChart CRD)   [Kustomize]
│       ├── envoy-gateway/          # Gateway API ingress (hostNetwork on ingress) [Kustomize]
│       ├── external-dns/           # Cloudflare DNS sync                          [Kustomize]
│       ├── external-secrets/       # OCI Vault → K8s Secrets (K3s HelmChart CRD) [Kustomize]
│       ├── gatus/                  # Status page at /status                       [Helm chart]
│       ├── kube-prometheus-stack/  # Prometheus+Grafana+node-exporter+KSM         [Helm chart wrapper]
│       └── loki/                   # Loki (monolithic) + Promtail                 [Helm chart wrapper]
├── components/terraform/         # Atmos thin wrappers (no logic, just delegation)
│   ├── cluster/
│   ├── dns/
│   ├── iam/
│   ├── networking/
│   └── vault/
├── modules/                      # Terraform modules (all logic lives here)
│   ├── cluster/                  # 3 ARM instances + cloud-init templates
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   ├── versions.tf
│   │   └── user-data/
│   │       ├── ingress.yaml      # NAT setup, iptables rules
│   │       ├── server.yaml       # K3s server + ArgoCD bootstrap
│   │       └── worker.yaml       # K3s agent join
│   ├── dns/                      # Cloudflare static A records (ingress IP bootstrap)
│   ├── iam/                      # OCI Dynamic Group + policies (Instance Principal)
│   ├── networking/               # VCN, subnets, internet gateway, security lists
│   └── vault/                    # OCI Vault + initial secrets
├── stacks/
│   ├── catalog/                  # Per-component default var definitions
│   ├── mixins/                   # Reusable region/stage config snippets
│   ├── orgs/glg/prod/fra.yaml    # Production stack: glg-prod-fra
│   └── workflows/
│       └── cluster.yaml          # Ordered multi-step workflows (apply/plan/destroy/validate)
├── secrets/
│   └── prod/
│       ├── secrets.yaml          # SOPS-encrypted (committed — safe)
│       ├── secrets.decrypted.yaml  # Plaintext (gitignored — NEVER commit)
│       ├── secrets.example.yaml  # Template with placeholder values
│       ├── www.yaml              # SOPS-encrypted app secrets
│       ├── www.decrypted.yaml    # Plaintext (gitignored)
│       └── www.example.yaml      # Template: mixpanel_token, site_url
├── scripts/
│   ├── _lib.sh                   # Shared shell functions
│   ├── atmos.sh                  # Atmos wrapper (injects env, workspace)
│   ├── setup.sh                  # Tool validation + SOPS key generation
│   ├── sops.sh                   # SOPS encrypt/decrypt helper
│   └── with-secrets.sh           # Decrypts SOPS → exports TF_VARs → runs command
├── atmos.yaml                    # Atmos config (stack paths, component base path)
├── Makefile                      # Primary operator interface
└── README.md                     # Human-facing documentation
```

---

## 4. Infrastructure Components

### Deployed Kubernetes Applications

#### `kubernetes/apps/www` — Portfolio Website
- **Image**: `ghcr.io/fapiper/fabianpiper.com/www:latest`
- **Replicas**: 2
- **Deployed as**: Custom **Helm chart** (`Chart.yaml` + `values.yaml` + `templates/`)
- **Image updates**: ArgoCD Image Updater (digest strategy) monitors `:latest` tag → resolves sha256 digest → writes to `.argocd-source-www.yaml` via git → ArgoCD syncs with `image@sha256:…` reference
- **Image Updater annotations**: Live on the dedicated `bootstrap/templates/www.yaml` Application (NOT on the Deployment)
- **URLs**: `https://www.fabianpiper.com`, `https://glg.fabianpiper.com`
- **Secrets**: `regcred` (GHCR pull secret), app env vars from OCI Vault via ExternalSecret

#### `kubernetes/infrastructure/cert-manager` — TLS Certificates
- Installed via K3s `HelmChart` CRD (not ArgoCD Helm source)
- Issues Let's Encrypt certificates for all public-facing services
- ClusterIssuer for ACME HTTP-01 challenge

#### `kubernetes/infrastructure/envoy-gateway` — Ingress
- GatewayClass `eg`, Gateway `public-gateway` in namespace `envoy-gateway-system`
- Envoy pods: `hostNetwork: true`, NodeSelector `role: ingress`
- Listens on ports 80 (HTTP) and 443 (HTTPS)
- All HTTPRoutes attach to `public-gateway`

#### `kubernetes/infrastructure/external-dns` — DNS Automation
- Syncs Cloudflare DNS records **dynamically** from HTTPRoutes and annotated Services
- Cloudflare API token sourced from OCI Vault
- Runs continuously in-cluster; reconciles on every change to HTTPRoute or Service resources

> **DNS layering**: Two independent mechanisms manage Cloudflare DNS.
> `modules/dns` (Terraform) creates the **static bootstrap A records** (`www.fabianpiper.com`, `glg.fabianpiper.com` → ingress IP) as a one-time provisioning step.
> `external-dns` (K8s) manages **dynamic records** derived from Gateway API HTTPRoutes at runtime.
> Both write to the same Cloudflare zone; Terraform records are stable and rarely change, while `external-dns` keeps route-level records in sync.

#### `kubernetes/infrastructure/external-secrets` — Secret Sync
- Installed via K3s `HelmChart` CRD
- `ClusterSecretStore` authenticates to OCI Vault via **Instance Principal** (no static credentials)
- `ExternalSecret` → creates K8s `Secret` by referencing OCI Vault secret names

#### `kubernetes/infrastructure/argocd-image-updater` — Image Automation
- Polls GHCR for the `:latest` tag on the `www` image every 2 minutes
- Write-back: `git` method using `argocd/argocd-image-updater-github-creds` secret
- Update strategy: `digest` — resolves the sha256 digest of `:latest` and writes it to `image.digest` Helm value
- Annotations live on the **Application** resource (`bootstrap/templates/www.yaml`), not on the Deployment

#### `kubernetes/infrastructure/kube-prometheus-stack` — Metrics Collection + Dashboard
- **Deployed as**: **Helm chart wrapper** around `prometheus-community/kube-prometheus-stack`
- **Chart version**: `82.18.0` (Prometheus Operator v0.89.0)
- **Namespace**: `kube-prometheus-stack`
- **Components enabled**: Prometheus (v3.x), Grafana (via sub-chart), node-exporter (DaemonSet), kube-state-metrics
- **Components disabled**: Alertmanager, Pushgateway
- **Grafana URL**: `https://glg.fabianpiper.com/grafana`
- **Grafana admin credentials**: OCI Vault → ExternalSecret (wave `-5`) → `grafana-admin` K8s Secret
- **Grafana datasources**: Prometheus (default, auto-provisioned by chart) + Loki (additionalDataSources)
- **Grafana service**: `grafana.kube-prometheus-stack.svc.cluster.local:80` (fullnameOverride: grafana)
- **Prometheus access**: ClusterIP only — `prometheus-operated.kube-prometheus-stack.svc.cluster.local:9090`
- **Prometheus storage**: 5 Gi PVC (K3s local-path)
- **Grafana storage**: 2 Gi PVC (K3s local-path)
- **Scraping**: ServiceMonitor-based (Kubernetes API, nodes, kubelet, cAdvisor, kube-state-metrics)
- **Sync waves**: ExternalSecret wave `-5` (before upstream chart default wave `0`), HTTPRoute wave `25`
- **fullnameOverride**: `kps` (for kube-prometheus-stack resources), `grafana` (for Grafana service)
- **Dependency lock**: `Chart.lock` committed — run `helm dep update` after every version bump

#### `kubernetes/infrastructure/loki` — Log Aggregation
- **Deployed as**: **Helm chart wrapper** around `grafana/loki-stack`
- **Chart version**: `2.10.2` (Loki v2.9.3)
- **Namespace**: `loki`
- **Components**: Loki (monolithic/single-binary, filesystem storage) + Promtail (DaemonSet)
- **Loki service**: `loki.loki.svc.cluster.local:3100` (fullnameOverride: loki)
- **Grafana datasource URL**: `http://loki.loki.svc.cluster.local:3100`
- **Storage**: 5 Gi PVC (K3s local-path, no public route)
- **fullnameOverride**: `loki`
- **Dependency lock**: `Chart.lock` committed — run `helm dep update` after every version bump

#### `kubernetes/infrastructure/gatus` — Status Page
- **Deployed as**: Custom **Helm chart** (`Chart.yaml` + `values.yaml` + `templates/`)
- **Namespace**: `gatus`
- **URL**: `https://glg.fabianpiper.com/status` (no authentication)
- **Config**: Endpoints defined in `values.yaml` under `config.endpoints`, rendered into a ConfigMap
- **Monitored endpoints**: `www.fabianpiper.com`, `glg.fabianpiper.com`, `glg.fabianpiper.com/grafana`
- **Storage**: none (in-memory)
- **Sync waves**: ConfigMap wave `5`, Deployment + Service wave `10`, HTTPRoute wave `25`

### OCI Vault Secrets (Runtime)

| Secret Name | Consumer | Description |
|-------------|----------|-------------|
| `git-pat` | argocd-image-updater | GitHub PAT for GHCR read + git write-back |
| `git-username` | argocd-image-updater | GitHub username |
| `site-url` | www app | Public site URL |
| `mixpanel-token` | www app | Analytics token (optional) |
| `grafana-admin-password` | kube-prometheus-stack (Grafana) | Grafana admin password |

---

## 5. Setup & Deployment

### Prerequisites

```bash
# Verify required CLI tools
terraform version    # Must be >= 1.5
atmos version        # Must be >= 0.23
sops --version       # Must be >= 3.11
age --version        # Must be >= 1.3
bun --version        # Must be >= 1.3 (apps/www only)
oci --version        # OCI CLI

# Install missing tools
# Terraform:  https://developer.hashicorp.com/terraform/install
# Atmos:      brew install atmos  OR  go install github.com/cloudposse/atmos/cmd/atmos@latest
# SOPS:       brew install sops   OR  https://github.com/mozilla/sops/releases
# age:        brew install age    OR  https://github.com/FiloSottile/age/releases
# Bun:        curl -fsSL https://bun.sh/install | bash
# OCI CLI:    bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

### Makefile Interface

All operations go through `make`. Pattern: `<action>-<env>[-<component>]`

```bash
make help                    # List all targets

# Infrastructure lifecycle
make deploy-prod             # Full bootstrap: networking→iam→vault→cluster→dns
make plan-prod               # Dry-run all components
make plan-prod-cluster       # Dry-run cluster only
make apply-prod-networking   # Apply networking
make apply-prod-iam          # Apply IAM
make apply-prod-vault        # Apply vault
make apply-prod-cluster      # Apply cluster
make apply-prod-dns          # Apply DNS
make destroy-prod-cluster    # Destroy cluster (careful!)
make validate-prod           # terraform validate all modules

# Secrets management
make sops-setup              # Generate age keypair (one-time)
make sops-init-prod          # Create secrets/prod/.sops.yaml
make sops-encrypt-prod       # Encrypt *.decrypted.yaml → *.yaml
make sops-decrypt-prod       # Decrypt *.yaml → *.decrypted.yaml

# Application
make dev-www                 # Local Astro dev server
make build-www               # Production build locally
```

### Initial Deployment

```bash
# 1. Clone
git clone https://github.com/fapiper/fabianpiper.com.git
cd fabianpiper.com

# 2. Generate SOPS age key (one-time)
make setup
# Creates: secrets/.sops.key  ← NEVER COMMIT THIS FILE
# Creates: secrets/prod/.sops.yaml

# 3. Configure infrastructure secrets
cp secrets/prod/secrets.example.yaml secrets/prod/secrets.decrypted.yaml
# Edit — required values:
#   TF_VAR_user_ocid               OCI user OCID
#   TF_VAR_tenancy_ocid            OCI tenancy OCID
#   TF_VAR_compartment_ocid        OCI compartment OCID
#   TF_VAR_fingerprint             OCI API key fingerprint
#   TF_VAR_private_key_content     OCI API private key (PEM, multiline)
#   TF_VAR_private_key_path        ~/.oci/oci_api_key.pem
#   TF_VAR_region                  e.g. eu-frankfurt-1
#   TF_VAR_ssh_public_key_path     ~/.ssh/id_rsa.pub
#   TF_VAR_git_pat                 GitHub PAT (repo + packages scopes)
#   TF_VAR_git_username            GitHub username
#   TF_VAR_git_email               GitHub email
#   TF_VAR_git_repo_url            https://github.com/fapiper/fabianpiper.com.git
#   TF_VAR_cloudflare_api_token    Cloudflare API token (Zone:DNS:Edit)
#   TF_VAR_k3s_token               Cluster join token — generate with: uuidgen
#   TF_VAR_grafana_admin_password  Grafana admin password

# 4. Configure application secrets
cp secrets/prod/www.example.yaml secrets/prod/www.decrypted.yaml
# Edit:
#   TF_VAR_mixpanel_token  Mixpanel project token (or "disabled")
#   TF_VAR_site_url        https://www.fabianpiper.com

# 5. Encrypt
make sops-encrypt-prod
# Creates: secrets/prod/secrets.yaml + secrets/prod/www.yaml (safe to commit)

# 6. Add age key to GitHub Actions secrets
cat secrets/.sops.key
# Navigate: https://github.com/fapiper/fabianpiper.com/settings/secrets/actions
# Create secret: SOPS_AGE_KEY  (paste full output including "AGE-SECRET-KEY-...")

# 7. Deploy (~15–20 min)
make deploy-prod
# Order: networking → iam → vault → cluster → dns
# cloud-init on server node installs K3s, ArgoCD, and applies root.yaml automatically
```

### Verify Deployment

```bash
INGRESS_IP="<your-ingress-public-ip>"

# Get ingress IP from Terraform outputs
make plan-prod-cluster 2>&1 | grep ingress_public_ip

# SSH connectivity
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP 'echo ok'

# Private subnet access via jump host
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP 'ssh ubuntu@10.0.2.10 hostname'
# Expected: server

# Cluster nodes
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get nodes -o wide'
# Expected: 3 nodes, all Ready

# ArgoCD pods
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n argocd'

# ArgoCD admin password
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl -n argocd get secret argocd-initial-admin-secret \
   -o jsonpath="{.data.password}" | base64 -d && echo'

# ArgoCD UI (port-forward to http://localhost:8080)
ssh -i ~/.ssh/id_rsa -L 8080:10.0.2.10:80 ubuntu@$INGRESS_IP -N &

# Public endpoints
curl -sI https://www.fabianpiper.com         | head -1  # HTTP/2 200
curl -sI https://glg.fabianpiper.com/grafana | head -1  # HTTP/2 302
```

### Local kubectl Access

```bash
INGRESS_IP="<your-ingress-public-ip>"

ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig-prod.yaml

sed -i "s/127.0.0.1/$INGRESS_IP/" kubeconfig-prod.yaml

export KUBECONFIG=./kubeconfig-prod.yaml
kubectl get nodes
kubectl get pods -A
```

---

## 6. Code Style & Conventions

### Terraform

- **Format**: `terraform fmt -recursive` before every commit
- **Validate**: `terraform validate` in each changed module directory
- **Naming**:
  - Resources: `<provider>_<resource_type>.<descriptive_name>` (e.g., `oci_core_vcn.default`)
  - Variables: `snake_case`
  - Module directories: `kebab-case`
- **Module structure** (all four files are mandatory):
  ```
  main.tf       # All resources
  variables.tf  # All inputs — type + description required on every variable
  outputs.tf    # All outputs — description required; sensitive = true where applicable
  versions.tf   # required_version + required_providers with pinned version constraints
  ```
  Optional: `data.tf`, `locals.tf`
- **Variables**: `default = null` for optional; `validation` blocks for constrained inputs
- **Never commit**: `.tfstate`, `.tfvars` containing real values, `*.decrypted.*`

### Kubernetes Manifests

- **One resource type per file**: `deployment.yaml`, `service.yaml`, `httproute.yaml`, etc.
- **Kustomize dirs** (argocd-image-updater, cert-manager, envoy-gateway, external-dns, external-secrets): must have `kustomization.yaml` listing all resources
- **Helm chart dirs** (prometheus, grafana, www): must have `Chart.yaml` + `values.yaml` + `templates/` — no `kustomization.yaml` needed (ArgoCD auto-detects Helm when `Chart.yaml` is present)
- **Required labels on ALL resources**:
  ```yaml
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <app-name>
    app.kubernetes.io/part-of: infrastructure   # or "portfolio"
  ```
- **Required resource limits on ALL containers**:
  ```yaml
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  ```
  Check OCI free tier headroom (§10) before setting limits for new services.
- **Sync waves**: Annotate with `argocd.argoproj.io/sync-wave: "<N>"`. Follow the table in §2.
  **PVC and Deployment must always share the same sync wave.**
- **Namespaces**: Directory name == namespace (apps and infrastructure components both).
- **Image tags**: App images use `:latest` (managed by ArgoCD Image Updater). Infrastructure images use explicit pinned version tags.

### Helm Charts

All custom charts in this repo follow these conventions:

- **Structure** (mandatory files):
  ```
  Chart.yaml          # apiVersion: v2, name, description, type: application, version, appVersion
  values.yaml         # All tuneable defaults — every value must be used in a template
  templates/
    _helpers.tpl      # Named templates: <chart>.name, <chart>.labels, <chart>.selectorLabels
    <resource>.yaml   # One resource kind per file (same as raw manifest convention)
  ```
- **Named templates** (`_helpers.tpl`): always define `<chart>.name`, `<chart>.labels`, `<chart>.selectorLabels`
- **Common labels**: use `{{- include "<chart>.labels" . | nindent 4 }}` on every resource
- **Resources block**: use `{{- toYaml .Values.resources | nindent 12 }}` — never hard-code limits
- **Sync waves**: keep `argocd.argoproj.io/sync-wave` annotations in templates (same rules as raw manifests)
- **PVC + Deployment same wave**: still required even inside a Helm chart — annotate both templates identically
- **ESO template escaping**: External Secrets Operator uses `{{ }}` Go-template expressions evaluated at runtime. To embed them in a Helm template without Helm interpreting them, use `{{ "{{" }}` and `{{ "}}" }}`:
  ```yaml
  "username": "{{ "{{" }} .my_secret | trim {{ "}}" }}"
  ```
- **Validation**: `helm lint kubernetes/<path>/` before committing a chart change

### Shell Scripts

- **Shebang**: `#!/usr/bin/env bash`
- **Error handling**: `set -euo pipefail` at top of every script
- **Filenames**: `kebab-case.sh`
- **Lint**: `shellcheck <script>` before commit

### Git Commits

Conventional Commits: `<type>(<scope>): <description>`

| Type | When |
|------|------|
| `feat` | New feature or component |
| `fix` | Bug fix |
| `chore` | Maintenance (deps, formatting) |
| `docs` | Documentation only |
| `refactor` | Restructuring without behavior change |
| `ci` | GitHub Actions changes |

Examples: `feat(k8s): add prometheus`, `fix(grafana): correct datasource url`, `docs: update AGENTS.md`

---

## 7. Development Workflow

### Application Changes (apps/www)

```bash
cd apps/www
bun install
bun run dev            # http://localhost:4321

# Validate before push
bun run astro check    # Must report 0 errors
bun run build          # Production build — must exit 0
bun run preview        # Smoke-test prod build at http://localhost:4321

# Deploy — just push to main
git add apps/www/
git commit -m "feat(www): <description>"
git push origin main
# → GitHub Actions builds linux/amd64 + linux/arm64
# → Pushes ghcr.io/fapiper/fabianpiper.com/www:latest and www:<sha>
# → ArgoCD Image Updater detects :latest digest change (~2 min), writes sha256 to git
# → ArgoCD syncs deployment with new image@sha256 reference (~30 sec)
```

### Infrastructure Changes

```bash
# Edit modules/<module>/
terraform fmt -recursive
cd modules/<module> && terraform validate && cd ../..

make plan-prod-<component>    # Review diff carefully
make apply-prod-<component>

# Verify
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get nodes'

git add modules/<module>/
git commit -m "feat(<module>): <description>"
```

### Adding a New Kubernetes Service

Two patterns — choose based on complexity:

**Option A – Kustomize (simple, few resources, no parameterisation needed)**:
```bash
# 1. Create directory (name = ArgoCD app name = namespace)
mkdir -p kubernetes/infrastructure/<service-name>

# 2. Create required files:
#    deployment.yaml, service.yaml, kustomization.yaml
#    Optional: httproute.yaml, external-secret.yaml, pvc.yaml

# 3. Validate locally
kubectl kustomize kubernetes/infrastructure/<service-name>/

# 4. Commit and push
git add kubernetes/infrastructure/<service-name>/
git commit -m "feat(k8s): add <service-name>"
git push origin main
```

**Option B – Helm chart (recommended for new services; reusable, parameterised)**:
```bash
# 1. Create directory (name = ArgoCD app name = namespace)
mkdir -p kubernetes/infrastructure/<service-name>/templates

# 2. Create Chart.yaml, values.yaml, templates/_helpers.tpl, templates/<resource>.yaml
#    ArgoCD auto-detects Chart.yaml → switches to Helm mode automatically

# 3. Validate locally
helm lint kubernetes/infrastructure/<service-name>/
helm template <service-name> kubernetes/infrastructure/<service-name>/

# 4. Commit and push
git add kubernetes/infrastructure/<service-name>/
git commit -m "feat(k8s): add <service-name>"
git push origin main
```

**After pushing (both options)**:
```bash
# 5. Trigger immediate ArgoCD discovery
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl annotate applicationset infrastructure \
   -n argocd argocd.argoproj.io/refresh=normal --overwrite'

# 6. Monitor
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get applications -n argocd -w'
```

### Forcing Immediate ArgoCD Sync

```bash
# Re-discover all directories (ApplicationSet level)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl annotate applicationset infrastructure \
   -n argocd argocd.argoproj.io/refresh=normal --overwrite'

# Refresh a specific Application
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl annotate application <app-name> \
   -n argocd argocd.argoproj.io/refresh=normal --overwrite'

# Hard refresh (clears cache, re-evaluates from scratch)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl annotate application <app-name> \
   -n argocd argocd.argoproj.io/refresh=hard --overwrite'
```

### Adding New Terraform Modules

```bash
# 1. Create module
mkdir -p modules/<module-name>
touch modules/<module-name>/{main.tf,variables.tf,outputs.tf,versions.tf}

# 2. Create Atmos component wrapper (copy from existing, e.g. components/terraform/cluster/)
mkdir -p components/terraform/<module-name>

# 3. Add to stacks/workflows/cluster.yaml (correct position in apply/plan/destroy/validate)

# 4. Reference in stacks/orgs/glg/prod/fra.yaml if component-specific vars needed
```

---

## 8. Observability

### Grafana

- **URL**: `https://glg.fabianpiper.com/grafana`
- **Login**: username `admin`, password from OCI Vault (`grafana-admin-password`)
- **Datasources**: Prometheus (default, auto-provisioned by kube-prometheus-stack) + Loki (additionalDataSources)
- **Internal service**: `grafana.kube-prometheus-stack.svc.cluster.local:80`

**Local port-forward**:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 "sudo kubectl port-forward svc/grafana 3000:80 -n kube-prometheus-stack &>/dev/null &"'
ssh -i ~/.ssh/id_rsa -L 3000:10.0.2.10:3000 ubuntu@$INGRESS_IP -N &
# Open: http://localhost:3000/grafana
```

### Prometheus

- **Internal URL**: `http://prometheus-operated.kube-prometheus-stack.svc.cluster.local:9090`
- **No public HTTPRoute** — intentionally internal-only, accessible via Grafana datasource

**Local port-forward**:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 "sudo kubectl port-forward svc/prometheus-operated 9090:9090 -n kube-prometheus-stack &>/dev/null &"'
ssh -i ~/.ssh/id_rsa -L 9090:10.0.2.10:9090 ubuntu@$INGRESS_IP -N &
# Open: http://localhost:9090
```

**Verify targets are healthy** (after port-forward):
```bash
curl -s http://localhost:9090/api/v1/targets | \
  jq '.data.activeTargets[] | {job: .labels.job, health: .health, error: .lastError}'
# All entries should show "health": "up"
```

**Active scrape jobs** (ServiceMonitor-based, managed by kube-prometheus-stack):

| Job | Target | Auth |
|-----|--------|------|
| `prometheus` | Prometheus itself | None (localhost) |
| `kubernetes-apiservers` | K8s API server | HTTPS + bearer token |
| `kubernetes-nodes` | kubelet on each node | HTTPS + bearer token |
| `kubernetes-cadvisor` | cAdvisor on each node | HTTPS + bearer token |
| `kube-state-metrics` | kube-state-metrics pod | HTTP |
| `node-exporter` | node-exporter DaemonSet (all nodes) | HTTP |

### Loki

- **Internal URL**: `http://loki.loki.svc.cluster.local:3100`
- **No public route** — accessed via Grafana Loki datasource
- **Promtail**: DaemonSet on all 3 nodes, scrapes `/var/log/containers`

### Gatus Status Page

- **URL**: `https://glg.fabianpiper.com/status`
- **No authentication** — public read-only status page
- **Endpoints monitored**: www.fabianpiper.com, glg.fabianpiper.com, glg.fabianpiper.com/grafana
- **Config**: edit `kubernetes/infrastructure/gatus/values.yaml` → `config.endpoints`

### Recommended Grafana Dashboard Imports

| Dashboard | Grafana ID | What it shows |
|-----------|-----------|---------------|
| Kubernetes cluster overview | `3119` | Node CPU / RAM / disk |
| Kubernetes pod resources | `6417` | Per-pod resource usage |
| Prometheus stats | `2` | Prometheus self-monitoring |
| Loki Logs Explorer | `13639` | Log browsing via Loki |

Import: Grafana UI → Dashboards → New → Import → enter ID.

---

## 9. Testing

### Pre-commit Checklist

```bash
# Terraform (run after any .tf change)
terraform fmt -recursive
cd modules/<changed>/ && terraform validate && cd ../..

# Kubernetes manifests (run after any .yaml change)
# Kustomize dirs (argocd-image-updater, cert-manager, envoy-gateway, external-dns, external-secrets):
kubectl kustomize kubernetes/infrastructure/<changed>/
# Helm chart dirs (kube-prometheus-stack, loki, gatus, www):
helm lint kubernetes/infrastructure/<changed>/
helm template <changed> kubernetes/infrastructure/<changed>/

# Secret audit — must produce ZERO output
git grep -iE '(password|secret|token|private_key)\s*[:=]\s*[^$\{T]' \
  -- '*.tf' '*.yaml' '*.yml' '*.sh' \
  | grep -v 'TF_VAR' | grep -v 'secretKeyRef' | grep -v 'example' \
  | grep -v 'argocd.argoproj.io'

# Application (when apps/www changed)
cd apps/www
bun run astro check    # 0 type errors
bun run build          # exits 0
```

### Kubernetes Dry-run

```bash
# Client-side (no cluster required)
kubectl apply --dry-run=client -f kubernetes/infrastructure/<dir>/

# Server-side (admission webhook validation, requires cluster)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl apply --dry-run=server -f -' \
  < kubernetes/infrastructure/<dir>/deployment.yaml
```

### End-to-End CI/CD Smoke Test

```bash
# 1. Trigger
echo "# smoke-test-$(date +%s)" >> apps/www/README.md
git add apps/www/README.md
git commit -m "test: CI/CD smoke test"
git push origin main

# 2. Watch build
# https://github.com/fapiper/fabianpiper.com/actions

# 3. Watch image updater (~2 min after image push)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl logs deploy/argocd-image-updater \
   -n argocd --tail=20 -f'

# 4. Verify rollout
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout status deployment/www -n www'
# Expected: successfully rolled out

# 5. Smoke test
curl -sI https://www.fabianpiper.com | head -1
# Expected: HTTP/2 200
```

---

## 10. Constraints & Limits

### OCI Free Tier — CRITICAL: Never Exceed

| Resource | Limit | Current Usage | Headroom |
|----------|-------|---------------|----------|
| Compute — OCPUs (ARM) | 4 | 4 | **0 — cannot add nodes** |
| Compute — RAM | 24 GB | 24 GB | **0** |
| Block Storage | 200 GB | ~132 GB (~120 GB boot vols + 12 Gi PVCs) | ~68 GB |
| VCNs | 2 | 1 | 1 |
| Reserved Public IPs | 2 | 1 | 1 |
| Flexible Load Balancers | 1 | 0 (using NAT instance) | 1 |
| OCI Vault secrets | Unlimited | 1 vault, 5 secrets | Unlimited |
| Object Storage | 20 GB | 0 GB | 20 GB |

**ARM Instance Sizing** (100% utilized — cannot add nodes):

| Node | OCPUs | RAM | Schedulable RAM |
|------|-------|-----|----------------|
| ingress | 1 | 6 GB | ~5.5 GB |
| server | 2 | 12 GB | ~10 GB |
| worker | 1 | 6 GB | ~5.5 GB |

**Before adding a new service**:
1. Check current node pressure: `kubectl top nodes`
2. Sum new pod's CPU + memory requests against available headroom
3. Calculate PVC storage: `current ~127 GB + new PVC < 200 GB`
4. Verify block storage via OCI CLI:
   ```bash
   oci bv volume list --all --compartment-id <COMPARTMENT_OCID> \
     --query 'data[].{"name": "display-name", "size": "size-in-gbs"}' --output table
   ```

### Security Requirements

- **SSH**: Key-based only; password authentication disabled on all nodes
- **Network isolation**: Server and worker are in private subnet — only reachable via ingress jump host
- **TLS**: All public endpoints must be HTTPS (cert-manager + Let's Encrypt)
- **Secrets**:
  - Dev/IaC: SOPS+age — encrypt before commit; `*.decrypted.*` is gitignored
  - Runtime: OCI Vault via Instance Principal (zero static credentials on nodes)
  - CI/CD: SOPS-decrypted OCI creds + `GITHUB_TOKEN` for GHCR
- **Minimum-permission security lists**:
  - Ingress (public): TCP 22, 80, 443, 6443
  - Private subnet: Internal cluster traffic + UDP 8472 (Flannel VXLAN)

### Networking — Do Not Change

- VCN CIDR: `10.0.0.0/16` (subnet calculations hard-coded)
- Public subnet: `10.0.1.0/24`
- Private subnet: `10.0.2.0/24`
- Ingress static private IP: `10.0.1.10`
- Server static private IP: `10.0.2.10`

---

## 11. Troubleshooting

### General Diagnostics

```bash
# Overview
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get nodes,pods -A -o wide'

# ArgoCD app health
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get applications -n argocd'

# Resource pressure
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl top nodes && sudo kubectl top pods -A --sort-by=memory'

# Recent events
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get events -A --sort-by=.lastTimestamp | tail -30'
```

---

**Issue**: `terraform apply` — authentication error
**Cause**: OCI API key expired or misconfigured
```bash
make sops-decrypt-prod
oci iam user get --user-id "$(grep TF_VAR_user_ocid secrets/prod/secrets.decrypted.yaml \
  | cut -d: -f2 | tr -d ' ')"
# If 401: regenerate in OCI Console → User Settings → API Keys
# Update secrets.decrypted.yaml → make sops-encrypt-prod
```

---

**Issue**: Terraform state locked
**Cause**: Interrupted apply
```bash
# ONLY if confirmed no apply is currently running
rm -f components/terraform/<component>/terraform.tfstate.d/glg-prod-fra/.terraform.tfstate.lock.info
```

---

**Issue**: Pod stuck in `Pending`
```bash
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl describe pod <pod-name> -n <namespace>'
# "Insufficient cpu/memory"    → reduce requests in manifest
# "0/3 nodes … taints"         → check node taints/tolerations
# "ImagePullBackOff"           → check regcred secret / GHCR credentials
# "WaitForFirstConsumer" (PVC) → PVC and Deployment must be in the same sync wave (see §2)
```

---

**Issue**: PVC stuck in `Pending` — WaitForFirstConsumer deadlock
```bash
# Both must have the same argocd.argoproj.io/sync-wave value
grep 'sync-wave' kubernetes/infrastructure/<app>/pvc.yaml
grep 'sync-wave' kubernetes/infrastructure/<app>/deployment.yaml
# Fix: align wave numbers, commit, force ArgoCD refresh
```

---

**Issue**: Website not accessible / 502 / certificate error
```bash
# Envoy Gateway pods
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n envoy-gateway-system'

# HTTPRoute status
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get httproute -A'

# Certificate (must be Ready=True)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get certificate -A'

# DNS resolution
dig www.fabianpiper.com +short      # Must return ingress public IP
dig glg.fabianpiper.com +short

# external-dns logs
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl logs deploy/external-dns -n external-dns --tail=20'
```

---

**Issue**: Grafana shows "No data" or datasource error
```bash
# 1. Prometheus running?
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n kube-prometheus-stack'

# 2. Prometheus reachable from Grafana pod?
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl exec deploy/grafana -n kube-prometheus-stack -- \
   wget -qO- http://prometheus-operated:9090/-/healthy'
# Expected: Prometheus is Healthy.

# 3. Loki reachable from Grafana pod?
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl exec deploy/grafana -n kube-prometheus-stack -- \
   wget -qO- http://loki.loki.svc.cluster.local:3100/ready'
# Expected: ready

# 4. Restart Grafana to reload datasource provisioning
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deploy/grafana -n kube-prometheus-stack'
```

---

**Issue**: ArgoCD not discovering new directory
```bash
# Force immediate ApplicationSet refresh
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl annotate applicationset infrastructure \
   -n argocd argocd.argoproj.io/refresh=normal --overwrite'

# Validate kustomization locally first
kubectl kustomize kubernetes/infrastructure/<new-dir>/

# ApplicationSet controller logs
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl logs deploy/argocd-applicationset-controller \
   -n argocd --tail=30'
```

---

**Issue**: ArgoCD ApplicationSet controller crash / missing CRDs
```bash
# Check CRD
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get crd applicationsets.argoproj.io'

# If missing: delete namespace, cloud-init will recreate (~2 min)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl delete namespace argocd'
```

---

**Issue**: GitHub Actions failing — SOPS/OCI auth error
```bash
# Test local decryption
make sops-decrypt-prod
# If fails: secrets/.sops.key must exist and match the SOPS_AGE_KEY GitHub secret
# Check: https://github.com/fapiper/fabianpiper.com/settings/secrets/actions
```

---

**Issue**: Cannot SSH to instances
```bash
# Your current IP
curl -s ifconfig.me

# Verify OCI security list (managed by Terraform)
# OCI Console → Networking → VCN → Security Lists → public-sl
# Rule required: TCP/22 ingress from your IP/32
# Fix: update Terraform if your IP changed, then: make apply-prod-networking

ssh -v -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP   # Verbose output shows auth errors
```

---

## 12. Emergency Procedures

### Rollback Application

```bash
# Option A: Revert git commit → ArgoCD auto-syncs
git revert <bad-commit-hash>
git push origin main

# Option B: Roll back deployment revision
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout undo deployment/www -n www'

# Option C: Pin specific image SHA (bypasses Image Updater)
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl set image deployment/www \
   www=ghcr.io/fapiper/fabianpiper.com/www:<sha> -n www'
```

### Rollback Infrastructure

```bash
# Revert commit and re-apply
git revert <bad-commit-hash>
git push origin main
make apply-prod-<component>

# If state is corrupted — backup first!
cd components/terraform/<component>
terraform state pull > state-backup-$(date +%Y%m%d-%H%M%S).json
make destroy-prod-<component>
make apply-prod-<component>
```

### Manual State Backup

```bash
for component in networking iam vault cluster dns; do
  cd components/terraform/$component
  terraform state pull > ../../../../state-backup-${component}-$(date +%Y%m%d).json
  cd ../../../../
done

ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get all -A -o yaml' \
  > k8s-backup-$(date +%Y%m%d).yaml

ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl get applications -n argocd -o yaml' \
  > argocd-apps-$(date +%Y%m%d).yaml
```

### Force Restart Services

```bash
# Generic
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deployment/<name> -n <namespace>'

# All ArgoCD components
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deployment -n argocd'
```

### Complete Cluster Rebuild (Nuclear Option)

```bash
# 1. Back up state and K8s resources (see above)

# 2. Destroy
make destroy-prod-all   # type "yes" to confirm
# Wait ~10 min for full deletion

# 3. Redeploy (~15–20 min)
make deploy-prod
# ArgoCD reinstalls via cloud-init, root.yaml is re-applied automatically

# 4. Verify
make plan-prod   # Must show: No changes
curl -sI https://www.fabianpiper.com | head -1   # HTTP/2 200
```

---

## 13. Maintenance

### Routine Schedule

| Frequency | Task |
|-----------|------|
| Daily | Check GitHub Actions for failures |
| Weekly | Verify all ArgoCD apps are `Synced` + `Healthy` |
| Weekly | OCI Free Tier usage dashboard |
| Monthly | K3s version — update if security patch available |
| Monthly | Terraform provider versions in `modules/*/versions.tf` |
| Monthly | Audit OCI security list rules |
| Quarterly | Rotate Cloudflare API token → update OCI Vault + re-deploy external-dns |
| Quarterly | Rotate GitHub PAT → update OCI Vault `git-pat` secret |
| Quarterly | Review kube-prometheus-stack chart version (`kubernetes/infrastructure/kube-prometheus-stack/Chart.yaml`) |
| Quarterly | Test disaster recovery (full rebuild) |

### Updating Infrastructure Image Versions

```bash
# For wrapper charts (kube-prometheus-stack, loki): bump the dependency version
# in Chart.yaml and appVersion, then regenerate Chart.lock, then push.
# ArgoCD uses Chart.lock for reproducible dependency resolution — NEVER skip this step.
vim kubernetes/infrastructure/kube-prometheus-stack/Chart.yaml   # version: X.Y.Z
helm dependency update kubernetes/infrastructure/kube-prometheus-stack/
git add kubernetes/infrastructure/kube-prometheus-stack/Chart.yaml \
        kubernetes/infrastructure/kube-prometheus-stack/Chart.lock

vim kubernetes/infrastructure/loki/Chart.yaml                    # version: X.Y.Z
helm dependency update kubernetes/infrastructure/loki/
git add kubernetes/infrastructure/loki/Chart.yaml \
        kubernetes/infrastructure/loki/Chart.lock

# For the gatus custom chart: bump image.tag in values.yaml (no Chart.lock needed)
vim kubernetes/infrastructure/gatus/values.yaml
# e.g. tag: "v5.12.1" → "v5.x.x"

# For Kustomize apps: edit the deployment.yaml image field
vim kubernetes/infrastructure/<app>/deployment.yaml

git commit -m "chore(<app>): update to vX.Y.Z"
git push origin main
# ArgoCD auto-syncs within 30 seconds
```

### Updating Terraform Providers

```bash
# Edit version constraints in modules/*/versions.tf, then:
for m in networking iam vault cluster dns; do
  cd modules/$m && terraform init -upgrade && cd ../..
done

make plan-prod    # Review
make apply-prod   # Apply
```

### Updating K3s (In-Place)

```bash
# Update server first, then worker
ssh -i ~/.ssh/id_rsa ubuntu@$INGRESS_IP \
  'ssh ubuntu@10.0.2.10 "curl -sfL https://get.k3s.io | \
   INSTALL_K3S_VERSION=v1.29.x+k3s1 sh -"'
# Repeat for worker node
```

---

## 14. Agent Completion Checklist

Before marking any task complete, verify **all applicable items**:

**If Terraform files changed**:
- [ ] `terraform fmt -recursive` — no output (already formatted)
- [ ] `terraform validate` in each affected module directory — exits 0
- [ ] `make plan-prod-<component>` reviewed — no unexpected changes
- [ ] Block storage impact calculated if new PVCs added (current ~132 GB, limit 200 GB)
- [ ] Compute unchanged — no new OCI instances (currently at 100% free tier)

**If Kubernetes manifests changed**:
- [ ] For **Kustomize** dirs: `kubectl kustomize kubernetes/<path>/` — no YAML errors
- [ ] For **Helm** chart dirs: `helm lint kubernetes/<path>/` — exits 0
- [ ] Required labels on all resources (`app.kubernetes.io/name/instance/part-of`)
- [ ] Resource `requests` AND `limits` defined on all containers
- [ ] PVC sync wave == Deployment sync wave (WaitForFirstConsumer)
- [ ] `kustomization.yaml` updated if new files added to a **Kustomize** dir
- [ ] `Chart.yaml` present and `helm lint` passes if using Helm
- [ ] For **wrapper charts** (kube-prometheus-stack, loki): `helm dependency update kubernetes/<path>/` run and `Chart.lock` committed

**Security**:
- [ ] No plaintext secrets in code:
  ```bash
  git grep -iE '(password|secret|token|private_key)\s*[:=]\s*[^$\{T]' \
    -- '*.tf' '*.yaml' '*.yml' '*.sh' \
    | grep -v 'TF_VAR' | grep -v 'secretKeyRef' | grep -v 'example' \
    | grep -v 'argocd.argoproj.io'
  # Must produce ZERO output
  ```
- [ ] No `*.decrypted.*` files staged for commit (`git status` check)

**Process**:
- [ ] Commit uses conventional commit format: `<type>(<scope>): <description>`
- [ ] AGENTS.md updated if project structure, component inventory, or commands changed
- [ ] CI/CD pipeline passes if `apps/` or `.github/workflows/` changed

---

## 15. Reference Links

| Resource | URL |
|----------|-----|
| Repository | https://github.com/fapiper/fabianpiper.com |
| OCI Free Tier | https://www.oracle.com/cloud/free/ |
| OCI Documentation | https://docs.oracle.com/en-us/iaas/Content/home.htm |
| K3s Documentation | https://docs.k3s.io/ |
| Atmos Documentation | https://atmos.tools/ |
| ArgoCD Documentation | https://argo-cd.readthedocs.io/ |
| ArgoCD Image Updater | https://argocd-image-updater.readthedocs.io/ |
| Envoy Gateway | https://gateway.envoyproxy.io/ |
| Gateway API | https://gateway-api.sigs.k8s.io/ |
| cert-manager | https://cert-manager.io/docs/ |
| external-secrets | https://external-secrets.io/latest/ |
| external-dns | https://kubernetes-sigs.github.io/external-dns/ |
| Prometheus | https://prometheus.io/docs/ |
| Grafana | https://grafana.com/docs/grafana/latest/ |
| Helm | https://helm.sh/docs/ |
| SOPS | https://github.com/mozilla/sops |
| age | https://github.com/FiloSottile/age |
| Terraform OCI Provider | https://registry.terraform.io/providers/oracle/oci/latest/docs |
| GitHub Actions | https://docs.github.com/en/actions |
| GHCR | https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry |

---

**End of Agent Operations Manual**

This is the single source of truth for AI agents operating on this repository.
For human-readable documentation, see `README.md`.
