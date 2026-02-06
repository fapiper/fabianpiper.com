#!/usr/bin/env bash
# Initialize project - Creates config.yaml and secrets from examples
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config.yaml"
CONFIG_EXAMPLE="$PROJECT_ROOT/config.example.yaml"
SECRETS_DIR="$PROJECT_ROOT/secrets/prod"
SECRETS_FILE="$SECRETS_DIR/secrets.decrypted.yaml"
SECRETS_EXAMPLE="$SECRETS_DIR/secrets.example.yaml"

echo "=== Project Initialization ==="
echo

# Create config.yaml if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config.yaml from example..."
    cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
    echo "Created config.yaml"
    echo
    echo "Please edit config.yaml and fill in your values:"
    echo "   - OCI OCIDs (user, tenancy, compartment)"
    echo "   - GitHub username and repository"
    echo "   - Cloudflare domain"
    echo
    read -p "Press Enter after editing config.yaml..."
else
    echo "config.yaml already exists"
fi

# Create secrets file if it doesn't exist
mkdir -p "$SECRETS_DIR"
if [ ! -f "$SECRETS_FILE" ]; then
    echo
    echo "Creating secrets.decrypted.yaml from example..."
    cp "$SECRETS_EXAMPLE" "$SECRETS_FILE"

    # Auto-populate OCI credentials from config.yaml if available
    if [ -f "$CONFIG_FILE" ] && command -v yq &> /dev/null; then
        echo "Auto-populating OCI credentials from config.yaml..."

        TENANCY_OCID=$(yq eval '.oci.tenancy_ocid' "$CONFIG_FILE" 2>/dev/null || echo "")
        USER_OCID=$(yq eval '.oci.user_ocid' "$CONFIG_FILE" 2>/dev/null || echo "")

        if [ -n "$TENANCY_OCID" ] && [ "$TENANCY_OCID" != "null" ]; then
            sed -i.bak "s|TF_VAR_OCI_TENANCY_OCID:.*|TF_VAR_OCI_TENANCY_OCID: \"$TENANCY_OCID\"|" "$SECRETS_FILE"
        fi

        if [ -n "$USER_OCID" ] && [ "$USER_OCID" != "null" ]; then
            sed -i.bak "s|TF_VAR_OCI_USER_OCID:.*|TF_VAR_OCI_USER_OCID: \"$USER_OCID\"|" "$SECRETS_FILE"
        fi

        rm -f "${SECRETS_FILE}.bak"
    fi

    # Auto-generate K3s token
    if command -v openssl &> /dev/null; then
        K3S_TOKEN=$(openssl rand -base64 32)
        sed -i.bak "s/CHANGE_ME_generate_with_openssl_rand/$K3S_TOKEN/" "$SECRETS_FILE"
        rm -f "${SECRETS_FILE}.bak"
        echo "Auto-generated K3s token"
    fi

    echo "Created secrets.decrypted.yaml"
    echo
    echo "Please edit secrets/prod/secrets.decrypted.yaml and fill in:"
    echo "   - TF_VAR_OCI_FINGERPRINT: (auto-filled by 'make setup-oci')"
    echo "   - TF_VAR_OCI_PRIVATE_KEY_PATH: (auto-filled by 'make setup-oci')"
    echo "   - TF_VAR_GITHUB_PAT: GitHub Personal Access Token"
    echo "   - TF_VAR_GIT_USERNAME: Your GitHub username"
    echo "   - TF_VAR_GIT_REPO_URL: Your repository URL"
    echo "   - TF_VAR_CLOUDFLARE_API_TOKEN: Cloudflare API Token"
    echo
    echo "How to get these tokens:"
    echo "   GitHub PAT: https://github.com/settings/tokens (scope: read:packages)"
    echo "   Cloudflare: https://dash.cloudflare.com/profile/api-tokens"
    echo
    read -p "Press Enter after editing secrets.decrypted.yaml..."
else
    echo "secrets.decrypted.yaml already exists"
fi

echo
echo "Initialization complete!"
echo
echo "Next steps:"
echo "  1. Setup OCI: make setup-oci"
echo "  2. Setup SOPS: make setup"
echo "  3. Deploy: make bootstrap-prod"
