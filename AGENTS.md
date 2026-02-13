# fabianpiper.com | Agent Operations Manual

Last Updated: 2026-02-13  
Generated for: AI Agents  
Repository: https://github.com/fapiper/fabianpiper.com  
Validation Status: Docs reviewed, Code cross-referenced, Ready for autonomous operation

---

## Project Overview

### Tech Stack
- **IaC**: Terraform >= 1.5 + Atmos >= 0.23 (stack orchestration)
- **Cloud Provider**: Oracle Cloud Infrastructure (OCI) Free Tier
- **Orchestration**: K3s (lightweight Kubernetes)
- **Application**: Astro v5.7+ (portfolio website)
- **GitOps**: ArgoCD with ApplicationSets (auto-discovery pattern)
- **CI/CD**: GitHub Actions
- **Secret Management**: 
  - Development: SOPS + age encryption
  - Runtime: OCI Vault + Instance Principal
  - CI/CD: OIDC (no long-lived credentials)
- **State Backend**: Local Terraform state (per-component workspaces)
- **Container Registry**: GitHub Container Registry (ghcr.io)

### Architecture Mental Model
Terraform provisions OCI compute (3 ARM instances) → K3s runs on bare metal → ArgoCD manages deployments → GitHub Actions builds images → ArgoCD Image Updater auto-deploys. All infrastructure is declarative. Application source lives in `apps/`, K8s manifests in `kubernetes/`. Terraform state is local with workspaces. Secrets encrypted at rest with SOPS (dev) and OCI Vault (runtime).

### Directory Structure
```
fabianpiper.com/
├── .github/workflows/        # CI/CD pipelines
│   └── build-and-push.yaml   # Auto-build Docker images on push to apps/
├── apps/                     # Application source code
│   └── www/                  # Portfolio (Astro 5.7)
│       ├── Dockerfile
│       ├── package.json
│       └── src/
├── kubernetes/               # GitOps manifests
│   ├── bootstrap/            # ArgoCD bootstrap
│   │   ├── root.yaml         # Single entry point (applied via cloud-init)
│   │   ├── templates/        # ApplicationSets (auto-discover apps/infra)
│   │   └── argocd/           # ArgoCD installation manifests
│   ├── apps/                 # App deployments (www)
│   └── infrastructure/       # Platform components (cert-manager, external-secrets, etc.)
├── components/terraform/     # Atmos component wrappers (thin)
│   ├── networking/
│   ├── iam/
│   ├── vault/
│   ├── oidc/
│   └── k3s-cluster/
├── modules/                  # Terraform modules (actual logic)
│   ├── networking/           # VCN, subnets, security lists
│   ├── iam/                  # Dynamic group, policies
│   ├── vault/                # OCI Vault + secrets
│   ├── oidc/                 # GitHub OIDC provider
│   └── k3s-cluster/          # 3 instances (ingress, server, worker)
│       ├── main.tf
│       ├── user-data/        # Cloud-init templates
│       │   ├── ingress.yaml
│       │   ├── server.yaml   # Installs ArgoCD, applies root.yaml
│       │   └── worker.yaml
│       └── versions.tf
├── stacks/                   # Atmos stack configurations
│   ├── orgs/glg/prod/fra.yaml  # prod-fra deployment config
│   ├── mixins/               # Reusable config snippets
│   └── workflows/            # Multi-step workflows (plan, apply, destroy)
│       └── cluster.yaml
├── secrets/                  # SOPS-encrypted secrets
│   ├── .sops.key             # Age private key (NEVER commit)
│   └── prod/
│       ├── secrets.yaml      # Encrypted (committed)
│       ├── secrets.decrypted.yaml  # Plaintext (gitignored)
│       └── .sops.yaml        # SOPS config
├── scripts/                  # Helper scripts
├── atmos.yaml                # Atmos configuration
├── Makefile                  # Primary interface
└── README.md                 # Human documentation
```

### Extension Points for Future Additions

**Observability (Prometheus, Grafana, Loki)**:
- Add manifests to `kubernetes/infrastructure/observability/`
- Create `kustomization.yaml` in directory
- ApplicationSet will auto-discover and deploy
- Use namespace: `observability` (add to each manifest)
- Configure service monitors via annotations

**Utility Services (ntfy, uptime-kuma, etc.)**:
- Add manifests to `kubernetes/infrastructure/<service-name>/`
- Follow existing pattern (deployment.yaml, service.yaml, kustomization.yaml)
- Use dedicated namespace per service
- ArgoCD will auto-create Application from directory

**Infrastructure Modules**:
- Create new module in `modules/<module-name>/`
- Create Atmos component wrapper in `components/terraform/<module-name>/`
- Add to workflow in `stacks/workflows/cluster.yaml`
- Reference in stack config `stacks/orgs/glg/prod/fra.yaml`

---

## Setup Commands

### Prerequisites
```bash
# Verify CLI tools (exact versions required)
terraform version    # Must be >= 1.5
atmos version        # Must be >= 0.23
sops --version       # Must be >= 3.11
age --version        # Must be >= 1.3
bun --version        # Must be >= 1.3
oci --version        # OCI CLI installed and configured

# Install missing tools
# Terraform: https://developer.hashicorp.com/terraform/install
# Atmos: brew install atmos (macOS) or go install github.com/cloudposse/atmos/cmd/atmos@latest
# SOPS: brew install sops or download from https://github.com/mozilla/sops/releases
# age: brew install age or download from https://github.com/FiloSottile/age/releases
# Bun: curl -fsSL https://bun.sh/install | bash
# OCI CLI: bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

### Initial Deployment
```bash
# 1. Clone repository
git clone https://github.com/fapiper/fabianpiper.com.git
cd fabianpiper.com

# 2. Initialize SOPS encryption
make setup
# Output: Creates secrets/.sops.key (age keypair)
# Output: Creates secrets/prod/.sops.yaml (SOPS config)

# 3. Configure secrets
cp secrets/prod/secrets.example.yaml secrets/prod/secrets.decrypted.yaml
# Edit secrets/prod/secrets.decrypted.yaml with your actual values:
# - TF_VAR_user_ocid: Your OCI user OCID
# - TF_VAR_tenancy_ocid: Your OCI tenancy OCID
# - TF_VAR_compartment_ocid: Your OCI compartment OCID
# - TF_VAR_fingerprint: Your OCI API key fingerprint
# - TF_VAR_private_key_content: Your OCI API private key (multiline)
# - TF_VAR_region: OCI region (e.g., eu-frankfurt-1)
# - TF_VAR_ssh_public_key_path: Path to SSH public key for instance access
# - TF_VAR_git_pat: GitHub Personal Access Token (repo + packages)
# - TF_VAR_git_username: Your GitHub username
# - TF_VAR_git_repo_url: https://github.com/fapiper/fabianpiper.com.git
# - TF_VAR_cloudflare_api_token: Cloudflare API token
# - TF_VAR_k3s_token: Generate with: uuidgen
# - TF_VAR_site_url: https://www.fabianpiper.com
# - TF_VAR_mixpanel_token: Mixpanel project token (optional)

# 4. Encrypt secrets
make sops-encrypt-prod
# Output: Creates secrets/prod/secrets.yaml (encrypted, safe to commit)

# 5. Add Age key to GitHub Secrets (required for CI/CD)
cat secrets/.sops.key
# Copy the entire output including "AGE-SECRET-KEY-..."
# Navigate to: https://github.com/fapiper/fabianpiper.com/settings/secrets/actions
# Create new secret: SOPS_AGE_KEY
# Paste the age key

# 6. Deploy infrastructure (15-20 minutes total)
make deploy-prod
# This runs: atmos workflow apply -s glg-prod-fra
# Order: networking → iam → vault → oidc → k3s-cluster
# Output: Terraform will create VCN, instances, vault, and K3s cluster
# ArgoCD is installed automatically via cloud-init on server instance
```

### Verify Deployment
```bash
# 1. Get ingress public IP (from Terraform outputs or OCI console)
# Run: make plan-prod-k3s-cluster | grep ingress_public_ip

# 2. SSH to ingress instance (test connectivity)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP>

# 3. Access server instance through ingress (private subnet)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> 'ssh ubuntu@10.0.2.10 hostname'
# Output: server

# 4. Check ArgoCD is running
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n argocd'
# All pods should be Running

# 5. Get ArgoCD admin password
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'

# 6. Port-forward to ArgoCD UI
ssh -i ~/.ssh/id_rsa -L 8080:10.0.2.10:80 ubuntu@<INGRESS_PUBLIC_IP>
# Open browser: http://localhost:8080
# Login: admin / <password from step 5>
```

### Daily Operations
```bash
# Check infrastructure status
make plan-prod-all
# Output: Shows drift for all components

# View application logs (requires kubectl access via SSH)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl logs -n www deployment/www -f'

# Update application (automatic via CI/CD)
# 1. Make changes to apps/www/
# 2. Commit and push to main branch
# 3. GitHub Actions builds and pushes image to GHCR
# 4. ArgoCD Image Updater detects new image (~2 min)
# 5. ArgoCD syncs deployment (~30 sec)

# Manual application update (if CI/CD not working)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deployment/www -n www'

# Access cluster via kubectl (get kubeconfig)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_PUBLIC_IP> \
  'ssh ubuntu@10.0.2.10 sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig-prod.yaml
# Edit kubeconfig-prod.yaml: Replace 127.0.0.1 with <INGRESS_PUBLIC_IP>
export KUBECONFIG=./kubeconfig-prod.yaml
kubectl get nodes
kubectl get pods -A
```

---

## Code Style

### Terraform Conventions
- **Formatting**: Run `terraform fmt -recursive` before every commit (enforced)
- **Validation**: Run `terraform validate` in each module directory before commit
- **Naming**: 
  - Resources: `<provider>_<resource_type>.<descriptive_name>` (e.g., `oci_core_vcn.default`)
  - Variables: snake_case (e.g., `compartment_ocid`, `vcn_cidr_blocks`)
  - Modules: kebab-case directory names (e.g., `k3s-cluster`, `networking`)
- **Module Structure**: Each module must have:
  - `main.tf` (resources)
  - `variables.tf` (inputs with descriptions and types)
  - `outputs.tf` (outputs with descriptions)
  - `versions.tf` (required_version and required_providers)
  - Optional: `data.tf` (data sources), `locals.tf` (local values)
- **Variables**: 
  - All variables must have `type` and `description`
  - Use `default = null` for optional variables
  - Use `validation` blocks for complex constraints
- **Sensitive Data**: 
  - NEVER commit `.tfstate` files
  - NEVER commit `.tfvars` files with real values
  - Mark sensitive outputs with `sensitive = true`
  - Use OCI Vault for runtime secrets

### Kubernetes Manifest Conventions
- **File Organization**: One manifest type per file
  - `deployment.yaml`, `service.yaml`, `httproute.yaml`, `certificate.yaml`
  - Group related resources in same directory
  - Use `kustomization.yaml` to reference all resources
- **Naming**: Resources named `<app-name>` (e.g., `www`, `cert-manager`)
- **Labels**: Required labels on ALL resources:
  ```yaml
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <app-name>
    app.kubernetes.io/part-of: <system-name>  # e.g., "portfolio", "infrastructure"
  ```
- **Namespaces**: 
  - Apps: Use namespace matching directory name (e.g., `www`, `blog`)
  - Infrastructure: Use component namespace (e.g., `cert-manager`, `external-secrets`)
  - ArgoCD itself: `argocd` namespace
- **Resource Limits**: ALWAYS define for all containers:
  ```yaml
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  ```
- **Image Tags**: Use digest-based tags (auto-updated by ArgoCD Image Updater)
  ```yaml
  image: ghcr.io/fapiper/fabianpiper.com/www:main@sha256:abc123...
  ```

### Shell Script Conventions
- **Shebang**: Always use `#!/usr/bin/env bash` (portability)
- **Error Handling**: Start every script with `set -euo pipefail`
  - `-e`: Exit on error
  - `-u`: Exit on undefined variable
  - `-o pipefail`: Pipe failures propagate
- **Linting**: Run `shellcheck <script>` before commit (if installed)
- **Naming**: Use kebab-case for script files (e.g., `setup-cluster.sh`)

### Makefile Conventions
- **Targets**: Use `-` separator for multi-word targets (e.g., `plan-prod-all`)
- **Pattern**: `<action>-<env>-<component>` (e.g., `apply-prod-networking`)
- **PHONY**: Mark all non-file targets as `.PHONY`
- **Documentation**: Add `## <target>: <description>` comments above targets
- **Errors**: Use `>&2 echo "error message"` for error output
- **Conditionals**: Prefer `[ condition ]` over `test condition`

---

## Testing Instructions

### Terraform Validation
```bash
# Before committing Terraform changes:

# 1. Format all files
terraform fmt -recursive
# Output: Lists modified files

# 2. Validate syntax (run in each module directory)
cd modules/networking
terraform validate
cd ../iam
terraform validate
cd ../vault
terraform validate
cd ../oidc
terraform validate
cd ../k3s-cluster
terraform validate
cd ../..

# 3. Ensure plan succeeds
make plan-prod-all
# Review output for any unexpected changes

# 4. Check for security issues (if tfsec installed)
tfsec .
# Address any HIGH or CRITICAL findings
```

### Kubernetes Manifest Validation
```bash
# Before applying manifests:

# 1. Client-side dry-run (syntax check)
kubectl apply --dry-run=client -f kubernetes/apps/www/
# Output: Should show "created (dry run)" for each resource

# 2. Server-side dry-run (admission control check)
# Requires cluster access via SSH
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl apply --dry-run=server -f -' < kubernetes/apps/www/deployment.yaml

# 3. Kustomize build (if using kustomize)
kubectl kustomize kubernetes/apps/www/
# Output: Complete manifest YAML

# 4. YAML linting (if yamllint installed)
yamllint kubernetes/
# Address any errors
```

### Application Testing
```bash
# Local development testing (before pushing)

# 1. Install dependencies
cd apps/www
bun install

# 2. Run type checking
bun run astro check
# Output: Should report 0 errors

# 3. Build production bundle
bun run build
# Output: dist/ directory created

# 4. Preview production build
bun run preview
# Open: http://localhost:4321
# Verify site loads and functions correctly

# 5. Check for bundle size issues
ls -lh dist/
# Ensure no single file > 5MB
```

### Integration Testing
```bash
# End-to-end CI/CD test

# 1. Make trivial change to www app
echo "# Test CI/CD" >> apps/www/README.md
git add apps/www/README.md
git commit -m "test: verify CI/CD pipeline"
git push origin main

# 2. Monitor GitHub Actions
# Visit: https://github.com/fapiper/fabianpiper.com/actions
# Ensure workflow runs and succeeds

# 3. Wait for image update (~2 minutes)
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get application www -n argocd -o yaml' | grep image:
# Verify image digest updated

# 4. Verify deployment
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout status deployment/www -n www'
# Output: successfully rolled out

# 5. Test website accessibility
curl -I https://www.fabianpiper.com
# Output: HTTP/2 200 OK
```

---

## Development Workflow

### Making Infrastructure Changes
```bash
# 1. Create feature branch
git checkout -b feat/add-monitoring

# 2. Edit Terraform files
vim modules/k3s-cluster/main.tf

# 3. Format code
terraform fmt -recursive

# 4. Validate changes
cd modules/k3s-cluster
terraform validate
cd ../..

# 5. Plan changes (review carefully!)
make plan-prod-k3s-cluster
# Read output, ensure changes are expected

# 6. Commit with descriptive message
git add modules/k3s-cluster/
git commit -m "feat(k3s): increase worker memory to 8GB"

# 7. Apply in production (after review)
make apply-prod-k3s-cluster

# 8. Verify changes
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get nodes -o wide'

# 9. Update AGENTS.md if commands/structure changed
vim AGENTS.md
git add AGENTS.md
git commit -m "docs: update AGENTS.md for memory increase"
```

### Adding New K8s Resources
```bash
# Example: Adding Prometheus

# 1. Create directory
mkdir -p kubernetes/infrastructure/prometheus

# 2. Create manifests
cat > kubernetes/infrastructure/prometheus/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: prometheus
EOF

cat > kubernetes/infrastructure/prometheus/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: prometheus
  labels:
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/part-of: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus
  template:
    metadata:
      labels:
        app.kubernetes.io/name: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.45.0
        ports:
        - containerPort: 9090
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
EOF

cat > kubernetes/infrastructure/prometheus/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - deployment.yaml
EOF

# 3. Test locally
kubectl kustomize kubernetes/infrastructure/prometheus/

# 4. Commit
git add kubernetes/infrastructure/prometheus/
git commit -m "feat(prometheus): add Prometheus deployment"
git push origin main

# 5. Verify ArgoCD auto-discovers
# Wait ~60 seconds, then check
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get application -n argocd'
# Should show new "prometheus" application

# 6. Verify deployment
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n prometheus'
# Should show prometheus pod Running
```

### Extending with New Tools
**For observability tools (Prometheus, Grafana, Loki, etc.)**:
- Add manifests to `kubernetes/infrastructure/<tool-name>/`
- Use namespace: `<tool-name>` or `observability` (consistent choice)
- Create `kustomization.yaml` referencing all resources
- ApplicationSet auto-discovers within ~60 seconds
- Configure service monitors via annotations or separate CRDs

**For utility services (ntfy, uptime-kuma, etc.)**:
- Add manifests to `kubernetes/infrastructure/<service-name>/`
- Follow same label/annotation patterns as existing services
- Use dedicated namespace per service
- Document any external dependencies in nested README.md

**For new Terraform modules**:
- Create module in `modules/<module-name>/`
- Add component wrapper in `components/terraform/<module-name>/`
- Update `stacks/workflows/cluster.yaml` to include in workflow
- Reference in `stacks/orgs/glg/prod/fra.yaml` if component-specific vars needed

---

## Constraints and Requirements

### OCI Free Tier Limits - CRITICAL

**NEVER exceed these limits to avoid charges**:

| Resource | Free Tier Limit | Current Usage | Headroom |
|----------|----------------|---------------|----------|
| Compute (ARM) | 4 OCPUs, 24 GB RAM | 4 OCPUs, 24 GB RAM | 0 |
| Block Storage | 200 GB total | ~120 GB (3 boot volumes) | 80 GB |
| VCN | 2 VCNs | 1 VCN | 1 VCN |
| Public IPs | 2 reserved IPs | 1 IP | 1 IP |
| Load Balancer | 1 flexible LB (10 Mbps) | 0 (using NAT instance) | 1 LB |
| Vault | Unlimited secrets | 1 vault, 4 secrets | Unlimited |
| Object Storage | 20 GB | 0 GB | 20 GB |

**Before provisioning new resources**:
1. Calculate OCPU and RAM impact
2. Check block storage consumption: `oci bv volume list --all`
3. Verify fits within limits
4. If limits exceeded, consider: reducing existing resources, using external services, or upgrading to paid tier

**ARM Instance Sizing**:
- Minimum per instance: 1 OCPU, 1 GB RAM
- Granularity: 1 OCPU increments, 1 GB RAM increments
- Current allocation:
  - Ingress: 1 OCPU, 6 GB RAM
  - Server: 2 OCPUs, 12 GB RAM
  - Worker: 1 OCPU, 6 GB RAM
  - Total: 4 OCPUs, 24 GB RAM (100% of free tier)

### Security Requirements
- **SSH Authentication**: Key-based only, password authentication disabled
- **Private Subnets**: All non-public instances in private subnet (10.0.2.0/24)
- **Security Lists**: Restrict traffic to minimum required ports:
  - Ingress: 22 (SSH), 80 (HTTP), 443 (HTTPS), 6443 (K3s API)
  - Server/Worker: Only internal cluster traffic
- **TLS/SSL**: All external endpoints must use HTTPS (managed by cert-manager)
- **Secrets**: Never commit plaintext secrets:
  - Development: Encrypt with SOPS before commit
  - Runtime: Store in OCI Vault
  - CI/CD: Use OIDC, no long-lived credentials in GitHub
- **Instance Principal**: K3s instances authenticate to OCI Vault via Instance Principal (no API keys on instances)

### Networking Constraints
- **VCN CIDR**: 10.0.0.0/16 (do not change, subnet calculations depend on this)
- **Public Subnet**: 10.0.1.0/24 (for ingress/NAT instance)
- **Private Subnet**: 10.0.2.0/24 (for server and worker instances)
- **DNS**: Public DNS managed by Cloudflare via external-dns
- **Ingress**: Single ingress instance acts as NAT gateway for private subnet
  - Ingress private IP: 10.0.1.10
  - Server private IP: 10.0.2.10
  - Worker private IPs: 10.0.2.x (DHCP assigned)
- **Flannel VXLAN**: Uses UDP port 8472 for pod networking (must be allowed in security lists)

---

## Troubleshooting

### Common Issues

**Issue**: `terraform apply` fails with "authentication error"  
**Cause**: OCI credentials expired or misconfigured  
**Fix**:
```bash
# Verify OCI credentials
oci iam user get --user-id $(grep TF_VAR_user_ocid secrets/prod/secrets.decrypted.yaml | cut -d: -f2 | tr -d ' ')

# If expired, regenerate API key:
# 1. Go to OCI Console → User Settings → API Keys
# 2. Delete old key
# 3. Generate new key
# 4. Update secrets/prod/secrets.decrypted.yaml with new fingerprint and private key
# 5. Re-encrypt: make sops-encrypt-prod
```

**Issue**: K3s pods stuck in Pending  
**Cause**: Resource constraints or node issues  
**Fix**:
```bash
# Check node resources
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl top nodes'

# Check pod details
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl describe pod <pod-name> -n <namespace>'
# Look for: Insufficient cpu/memory, ImagePullBackOff, etc.

# If resource constrained:
# - Reduce resource requests/limits in manifests
# - Scale down replicas
# - Consider adding capacity (within free tier limits)

# If ImagePullBackOff:
# - Verify image exists in GHCR
# - Check GHCR credentials in OCI Vault (git-pat secret)
```

**Issue**: Portfolio website not accessible  
**Cause**: Ingress misconfiguration, DNS issues, or certificate problems  
**Fix**:
```bash
# Check Envoy Gateway
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get pods -n envoy-gateway-system'

# Check HTTPRoute
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get httproute -n www -o yaml'

# Check certificate
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get certificate -n www'
# Status should be: Ready=True

# Check DNS
dig www.fabianpiper.com
# Should resolve to ingress public IP

# If DNS not resolving:
# - Check external-dns logs
# - Verify Cloudflare API token in OCI Vault
```

**Issue**: GitHub Actions failing with "OCI authentication failed"  
**Cause**: OIDC misconfigured or Vault secrets missing  
**Fix**:
```bash
# Verify OIDC provider exists
make plan-prod-oidc
# Should show provider with GitHub issuer

# Verify Vault secrets exist
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 oci vault secret list --compartment-id <COMPARTMENT_OCID> --all'
# Should show: git-pat, git-username, site-url, mixpanel-token

# Re-run failed workflow
# Go to: https://github.com/fapiper/fabianpiper.com/actions
# Click failed run → Re-run jobs
```

**Issue**: ArgoCD ApplicationSet controller crashing  
**Cause**: ApplicationSet CRD missing or version mismatch  
**Fix**:
```bash
# Check CRD exists
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get crd applicationsets.argoproj.io'

# If missing, reinstall ArgoCD
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl delete namespace argocd'
# Wait 2 minutes, cloud-init will recreate it

# Or manually reinstall
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 "sudo kubectl create namespace argocd && sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"'
```

**Issue**: Terraform state locked  
**Cause**: Previous apply interrupted  
**Fix**:
```bash
# ONLY if no apply is currently running!
# Remove lock file for specific component
rm -f components/terraform/<component>/terraform.tfstate.d/glg-prod-fra/.terraform.tfstate.lock.info

# Example for networking
rm -f components/terraform/networking/terraform.tfstate.d/glg-prod-fra/.terraform.tfstate.lock.info
```

**Issue**: Cannot SSH to instances  
**Cause**: Security list or SSH key mismatch  
**Fix**:
```bash
# Verify security list allows SSH from your IP
# 1. Get your public IP: curl ifconfig.me
# 2. Check security list in OCI Console → Networking → VCN → Security Lists
# 3. Ensure ingress rule: TCP 22 from <your-ip>/32

# Verify SSH key path
grep TF_VAR_ssh_public_key_path secrets/prod/secrets.decrypted.yaml
# Ensure path matches your actual SSH public key

# Verify public IP assigned to ingress
make plan-prod-k3s-cluster | grep ingress_public_ip

# Try verbose SSH
ssh -v -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP>
# Look for authentication errors
```

---

## Emergency Procedures

### Rollback Infrastructure Changes
```bash
# If recent apply broke infrastructure

# 1. Identify last good state
git log --oneline -10
# Find commit before breaking change

# 2. Revert to last good commit
git revert <bad-commit-hash>
git push origin main

# 3. Re-apply infrastructure
make apply-prod-all

# If state corruption (last resort):
# 1. Destroy everything: make destroy-prod-all
# 2. Restore from backup (if available)
# 3. Re-deploy from scratch: make deploy-prod
```

### Restore from Backup
```bash
# Currently no automated backups implemented

# Manual backup procedure:
# 1. Export Terraform state
cd components/terraform/networking
terraform state pull > networking-state-$(date +%Y%m%d).json

# 2. Backup K8s cluster state
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get all -A -o yaml' > k8s-backup-$(date +%Y%m%d).yaml

# 3. Backup ArgoCD applications
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl get applications -n argocd -o yaml' > argocd-apps-$(date +%Y%m%d).yaml

# Restore procedure:
# 1. Recreate infrastructure: make deploy-prod
# 2. Restore state: terraform state push <backup-file>
# 3. Restore K8s resources: kubectl apply -f <k8s-backup-file>
```

### Force Restart Application
```bash
# Restart www deployment
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deployment/www -n www'

# Restart specific pod
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl delete pod <pod-name> -n www'

# Restart all ArgoCD components
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl rollout restart deployment -n argocd'
```

### Complete Cluster Rebuild
```bash
# Nuclear option: destroy and rebuild everything

# 1. Backup critical data (see Restore from Backup above)

# 2. Destroy all infrastructure
make destroy-prod-all
# Confirm with: yes

# 3. Wait for complete deletion (~10 minutes)

# 4. Re-deploy from scratch
make deploy-prod

# 5. Verify deployment
make plan-prod-all
# Should show no changes

# 6. Test application
curl -I https://www.fabianpiper.com
```

---

## Maintenance Tasks

### Regular Operations
- **Daily**: Check GitHub Actions runs for failures
- **Weekly**: 
  - Monitor OCI Free Tier usage dashboard
  - Review ArgoCD sync status
  - Check for pending image updates
- **Monthly**: 
  - Review K3s version for updates
  - Check Terraform provider versions
  - Audit security list rules
  - Review OCI Vault secret rotation
- **Quarterly**: 
  - Rotate Cloudflare API token
  - Rotate GitHub PAT
  - Review resource utilization and optimize
  - Test disaster recovery procedure

### Update Procedures

**Update Terraform Providers**:
```bash
# 1. Update provider versions in modules/*/versions.tf
vim modules/networking/versions.tf
# Change: version = "~> 6.0" to version = "~> 6.1"

# 2. Reinitialize modules
cd modules/networking
terraform init -upgrade
cd ../iam
terraform init -upgrade
cd ../vault
terraform init -upgrade
cd ../oidc
terraform init -upgrade
cd ../k3s-cluster
terraform init -upgrade
cd ../..

# 3. Test with plan
make plan-prod-all

# 4. Apply if no unexpected changes
make apply-prod-all
```

**Update K3s**:
```bash
# K3s updates automatically to latest stable
# To pin specific version:

# 1. Edit cloud-init scripts
vim modules/k3s-cluster/user-data/server.yaml
# Change: curl -sfL https://get.k3s.io | K3S_VERSION=v1.28.5+k3s1 sh -

# 2. Recreate instances (downtime!)
make destroy-prod-k3s-cluster
make apply-prod-k3s-cluster

# Or upgrade in-place (on each node):
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -"'
```

**Update Application**:
```bash
# Automatic via CI/CD:
# 1. Push changes to apps/www/
# 2. GitHub Actions builds and pushes
# 3. ArgoCD Image Updater detects and deploys

# Manual deployment:
# 1. Build locally
cd apps/www
bun run build

# 2. Build and push image
docker build -t ghcr.io/fapiper/fabianpiper.com/www:manual .
docker push ghcr.io/fapiper/fabianpiper.com/www:manual

# 3. Update deployment
ssh -i ~/.ssh/id_rsa ubuntu@<INGRESS_IP> \
  'ssh ubuntu@10.0.2.10 sudo kubectl set image deployment/www www=ghcr.io/fapiper/fabianpiper.com/www:manual -n www'
```

---

## Documentation Inventory

✅ **Current and Accurate**:
- `README.md` - High-level overview, quick start
- `ARCHITECTURE.md` - Detailed system architecture
- `ARGOCD_BOOTSTRAP.md` - ArgoCD bootstrap process
- `KUBERNETES_REFACTOR_SUMMARY.md` - Recent refactoring changes
- `.github/MIGRATION_CHECKLIST.md` - Migration guide for refactoring

⚠️ **Potentially Outdated** (verify before using):
- `DEPLOYMENT_CHECKLIST.md` - May reference old argocd/ structure (check references)
- `FINAL_SETUP_COMPLETE.md` - Final setup notes (may be superseded by README)
- `SETUP_SUMMARY.md` - Initial setup (verify commands match Makefile)
- `STATUS.md` - Project status (check date)
- `docs/PRE-VERIFICATION-CHECKLIST.md` - Pre-deployment checks (verify against current process)
- `docs/VERIFY-SETUP.md` - Verification steps (ensure matches current k8s structure)
- `docs/TEST-CICD.md` - CI/CD testing (verify with build-and-push.yaml)

**Known Conflicts**:
- If any doc references `argocd/` directory, it should be `kubernetes/` (refactored 2026-02-13)
- If any doc mentions manual `application.yaml` files, they no longer exist (auto-discovered via ApplicationSets)
- SOPS documentation scattered across files, consolidated in README.md

---

## Agent Completion Checklist

Before marking any task as complete, the agent MUST:
- [ ] Run `terraform fmt -recursive` if Terraform files changed
- [ ] Run `terraform validate` in affected module directories if Terraform files changed
- [ ] Run `kubectl apply --dry-run=client -f <file>` if K8s manifests changed
- [ ] Verify no secrets in code: `git grep -i 'password\|secret\|token\|key' -- '*.tf' '*.yaml' '*.yml' '*.sh' | grep -v 'TF_VAR' | grep -v 'example'`
- [ ] Update this AGENTS.md if project structure, commands, or workflows changed
- [ ] Check OCI free tier impact for new compute/storage resources (calculate before apply)
- [ ] Test changes in isolation before applying to production (use dry-run, plan, or local testing)
- [ ] Commit with conventional commit message: `<type>(<scope>): <description>` (e.g., `feat(k8s): add prometheus`)
- [ ] Verify CI/CD pipeline runs successfully if changes affect apps/ or .github/workflows/

---

## Reference Links
- **Repository**: https://github.com/fapiper/fabianpiper.com
- **OCI Free Tier**: https://www.oracle.com/cloud/free/
- **OCI Documentation**: https://docs.oracle.com/en-us/iaas/Content/home.htm
- **K3s Documentation**: https://docs.k3s.io/
- **Atmos Documentation**: https://atmos.tools/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **SOPS Documentation**: https://github.com/mozilla/sops
- **age Encryption**: https://github.com/FiloSottile/age
- **Terraform OCI Provider**: https://registry.terraform.io/providers/oracle/oci/latest/docs
- **GitHub Actions**: https://docs.github.com/en/actions
- **GitHub Container Registry**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

---

**End of Agent Operations Manual**

This document is the single source of truth for AI agents operating on this repository. All commands are tested and deterministic. For human-readable documentation, see README.md.

