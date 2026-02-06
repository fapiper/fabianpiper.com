#!/usr/bin/env bash
# Extract kubeconfig from K3s cluster
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KUBECONFIG_FILE="$PROJECT_ROOT/kubeconfig"

echo "=== Kubeconfig Extraction ==="
echo

# Get ingress IP
echo "📤 Getting ingress public IP..."
cd "$PROJECT_ROOT"
INGRESS_IP=$(atmos terraform output k3s-cluster ingress_public_ip -s prod-fra --format json | jq -r '.')

if [ -z "$INGRESS_IP" ] || [ "$INGRESS_IP" = "null" ]; then
    echo "❌ Failed to get ingress IP. Is k3s-cluster deployed?"
    exit 1
fi

echo "✅ Ingress IP: $INGRESS_IP"

# Wait for K3s to be ready
echo
echo "⏳ Waiting for K3s to initialize (this may take a few minutes)..."
sleep 60

# Try to extract kubeconfig with retries
MAX_RETRIES=10
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    echo "🔄 Attempt $((RETRY + 1))/$MAX_RETRIES..."

    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$INGRESS_IP \
        'ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@10.0.2.10 sudo cat /etc/rancher/k3s/k3s.yaml' \
        > "$KUBECONFIG_FILE" 2>/dev/null; then

        # Update server address
        sed -i.bak "s/127.0.0.1/$INGRESS_IP/g" "$KUBECONFIG_FILE"
        rm -f "${KUBECONFIG_FILE}.bak"

        echo "✅ Kubeconfig saved to: $KUBECONFIG_FILE"
        echo
        echo "📝 To use kubectl:"
        echo "   export KUBECONFIG=$KUBECONFIG_FILE"
        echo "   kubectl get nodes"
        echo
        echo "🎉 Kubeconfig extraction complete!"
        exit 0
    fi

    RETRY=$((RETRY + 1))
    if [ $RETRY -lt $MAX_RETRIES ]; then
        echo "⏳ Waiting 30 seconds before retry..."
        sleep 30
    fi
done

echo "Failed to extract kubeconfig after $MAX_RETRIES attempts"
echo
echo "Troubleshooting:"
echo "   1. Verify k3s-cluster is deployed: atmos terraform output k3s-cluster -s prod-fra"
echo "   2. Check ingress instance: ssh ubuntu@$INGRESS_IP"
echo "   3. Check K3s on server: ssh ubuntu@$INGRESS_IP 'ssh ubuntu@10.0.2.10 sudo systemctl status k3s'"
exit 1
