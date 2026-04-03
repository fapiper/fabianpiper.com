#!/usr/bin/env sh

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/scripts/_lib.sh"

ATMOS="$(find_bin atmos)"

ACTION="$1"
ENV="$2"
APP="$3"
STACK="glg-${ENV}-fra"

confirm() {
    CAP="$(printf '%s' "$ACTION" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$ACTION" | cut -c2-)"
    printf '\n>>> %s %s in %s? (yes/no): ' "$CAP" "$APP" "$ENV"
    read -r prompt < /dev/tty
    if [ "$prompt" != "yes" ]; then
        printf '\n%s cancelled.\n' "$CAP"
        exit 1
    fi
}

if [ "$APP" = "all" ]; then
    case "$ACTION" in
        apply)
            "$ATMOS" workflow plan -s "$STACK"
            confirm
            TF_CLI_ARGS_apply="-auto-approve" "$ATMOS" workflow apply -s "$STACK"
            ;;
        destroy)
            confirm
            TF_CLI_ARGS_destroy="-auto-approve" "$ATMOS" workflow destroy -s "$STACK"
            ;;
        *)
            "$ATMOS" workflow "$ACTION" -s "$STACK"
            ;;
    esac
else
    case "$ACTION" in
        destroy)
            confirm
            "$ATMOS" terraform destroy "$APP" -s "$STACK" -auto-approve
            ;;
        *)
            "$ATMOS" terraform "$ACTION" "$APP" -s "$STACK"
            ;;
    esac
fi
