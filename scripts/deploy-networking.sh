#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STACK_FILE="$PROJECT_ROOT/stacks/prod-fra.yaml"

echo "=== Networking Deployment & Configuration Update ==="
echo

# Deploy Networking
echo "Deploying networking infrastructure..."
cd "$PROJECT_ROOT"
atmos terraform apply networking -s prod-fra

echo
echo "Networking deployed successfully"
echo

# Get outputs
echo "📤 Extracting networking outputs..."
VCN_ID=$(atmos terraform output networking vcn_id -s prod-fra --format json | jq -r '.')
SUBNET_ID=$(atmos terraform output networking subnet_id -s prod-fra --format json | jq -r '.')

if [ -z "$VCN_ID" ] || [ "$VCN_ID" = "null" ]; then
    echo "Failed to get VCN ID"
    exit 1
fi

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "null" ]; then
    echo "Failed to get Subnet ID"
    exit 1
fi

echo "VCN ID: $VCN_ID"
echo "Subnet ID: $SUBNET_ID"

# Update prod-fra.yaml
echo
echo "Updating prod-fra.yaml with networking outputs..."
sed -i.bak \
    -e "s|vcn_id:.*|vcn_id: \"$VCN_ID\"|" \
    -e "s|public_subnet_id:.*|public_subnet_id: \"$SUBNET_ID\"|" \
    "$STACK_FILE"

rm -f "${STACK_FILE}.bak"

echo "prod-fra.yaml updated"
echo
echo "Networking setup complete!"
echo
echo "Next steps:"
echo "  1. Deploy IAM: make apply-prod-iam"
echo "  2. Deploy Vault: make apply-prod-vault"
echo "  3. Deploy K3s: make apply-prod-k3s-cluster"
