#!/usr/bin/env bash
# Backup Terraform state files locally
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups/terraform-state"
DATE=$(date +%Y%m%d-%H%M%S)

echo "=== Terraform State Backup ==="
echo

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Find and backup all state files
STATE_FILES=$(find "$PROJECT_ROOT/components/terraform" -name "terraform.tfstate" 2>/dev/null || true)

if [ -z "$STATE_FILES" ]; then
    echo "No state files found. Have you run terraform apply yet?"
    exit 0
fi

BACKUP_COUNT=0
while IFS= read -r state_file; do
    if [ -f "$state_file" ]; then
        # Get component name from path
        COMPONENT=$(basename $(dirname "$state_file"))

        # Copy with timestamp
        BACKUP_FILE="$BACKUP_DIR/${COMPONENT}_${DATE}.tfstate"
        cp "$state_file" "$BACKUP_FILE"

        echo "✅ Backed up: $COMPONENT → $BACKUP_FILE"
        ((BACKUP_COUNT++))
    fi
done <<< "$STATE_FILES"

echo
echo "✅ Backup complete! $BACKUP_COUNT state file(s) backed up"
echo "   Location: $BACKUP_DIR"
echo

# Optional: Clean up old backups (keep last 10)
CLEANUP=false
if [ "$CLEANUP" = true ]; then
    echo "Cleaning up old backups (keeping last 10)..."
    for component in networking iam vault k3s-cluster argocd-bootstrap; do
        ls -t "$BACKUP_DIR/${component}_"*.tfstate 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    done
fi

echo "💡 Tip: Run this script after important changes with: make backup-state"
