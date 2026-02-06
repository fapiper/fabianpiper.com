#!/usr/bin/env bash
# OCI Setup Script - Generates OCI API key and configures credentials
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$PROJECT_ROOT/secrets/prod"
CONFIG_FILE="$PROJECT_ROOT/config.yaml"
OCI_DIR="$HOME/.oci"
OCI_KEY="$OCI_DIR/oci_api_key.pem"
OCI_CONFIG="$OCI_DIR/config"

echo "=== OCI Setup ==="
echo

# Check if config.yaml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "config.yaml not found. Please copy config.example.yaml to config.yaml and fill in your values."
    exit 1
fi

# Extract values from config.yaml (requires yq)
if ! command -v yq &> /dev/null; then
    echo "⚠yq not found. Please install: https://github.com/mikefarah/yq"
    echo "    Or manually set OCI_USER_OCID, OCI_TENANCY_OCID, OCI_REGION"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    OCI_USER_OCID="${OCI_USER_OCID:-}"
    OCI_TENANCY_OCID="${OCI_TENANCY_OCID:-}"
    OCI_REGION="${OCI_REGION:-eu-frankfurt-1}"
else
    OCI_USER_OCID=$(yq eval '.oci.user_ocid' "$CONFIG_FILE")
    OCI_TENANCY_OCID=$(yq eval '.oci.tenancy_ocid' "$CONFIG_FILE")
    OCI_REGION=$(yq eval '.oci.region' "$CONFIG_FILE")
fi

# Create OCI directory
mkdir -p "$OCI_DIR"

# Generate OCI API key if it doesn't exist
if [ ! -f "$OCI_KEY" ]; then
    echo "Generating OCI API key pair..."
    openssl genrsa -out "$OCI_KEY" 2048
    chmod 600 "$OCI_KEY"
    openssl rsa -pubout -in "$OCI_KEY" -out "${OCI_KEY%.pem}_public.pem"
    echo "API key generated at: $OCI_KEY"
    echo
    echo "Next steps:"
    echo "   1. Copy the public key:"
    echo "      cat ${OCI_KEY%.pem}_public.pem"
    echo "   2. Add it to OCI Console:"
    echo "      https://cloud.oracle.com/identity/domains/my-profile/api-keys"
    echo "   3. Note the fingerprint shown after adding the key"
    echo
    read -p "Press Enter after adding the key to OCI Console..."
else
    echo "OCI API key already exists at: $OCI_KEY"
fi

# Get fingerprint
if command -v openssl &> /dev/null; then
    FINGERPRINT=$(openssl rsa -pubout -outform DER -in "$OCI_KEY" 2>/dev/null | openssl md5 -c | awk '{print $2}')
    echo "Fingerprint: $FINGERPRINT"
else
    read -p "Enter the fingerprint from OCI Console: " FINGERPRINT
fi

# Create/update OCI config
echo
echo "Creating OCI config file..."
cat > "$OCI_CONFIG" <<EOF
[DEFAULT]
user=$OCI_USER_OCID
fingerprint=$FINGERPRINT
tenancy=$OCI_TENANCY_OCID
region=$OCI_REGION
key_file=$OCI_KEY
EOF

echo "OCI configuration saved to: $OCI_CONFIG"

# Update secrets file if it exists
SECRETS_FILE="$SECRETS_DIR/secrets.decrypted.yaml"
if [ -f "$SECRETS_FILE" ]; then
    echo
    echo "Updating secrets with OCI credentials..."

    # Backup
    cp "$SECRETS_FILE" "${SECRETS_FILE}.bak"

    # Update OCI credentials in secrets
    sed -i.tmp \
        -e "s|TF_VAR_OCI_TENANCY_OCID:.*|TF_VAR_OCI_TENANCY_OCID: \"$OCI_TENANCY_OCID\"|" \
        -e "s|TF_VAR_OCI_USER_OCID:.*|TF_VAR_OCI_USER_OCID: \"$OCI_USER_OCID\"|" \
        -e "s|TF_VAR_OCI_FINGERPRINT:.*|TF_VAR_OCI_FINGERPRINT: \"$FINGERPRINT\"|" \
        -e "s|TF_VAR_OCI_PRIVATE_KEY_PATH:.*|TF_VAR_OCI_PRIVATE_KEY_PATH: \"$OCI_KEY\"|" \
        "$SECRETS_FILE"

    rm -f "${SECRETS_FILE}.tmp"
    echo "Secrets updated with OCI credentials"
fi

echo
echo "OCI setup complete!"
echo
echo "Next steps:"
echo "  1. Verify OCI CLI works: oci iam region list"
echo "  2. Continue with: make setup (for SOPS encryption)"
