#!/usr/bin/env sh

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/scripts/_lib.sh"

SOPS="$(find_bin sops)"

if [ $# -lt 2 ]; then
    echo "Usage: with-secrets.sh <env> <cmd> [args...]" >&2
    exit 1
fi

ENV="$1"
shift

SECRETS_ENV_DIR="$SECRETS_DIR/$ENV"

if [ ! -d "$SECRETS_ENV_DIR" ]; then
    echo "ERROR: Secrets directory not found: $SECRETS_ENV_DIR" >&2
    exit 1
fi

SECRET_FILES=""
for f in "$SECRETS_ENV_DIR"/*.yaml; do
    [ -f "$f" ] || continue
    case "$f" in
        *.example.yaml)   continue ;;
        *.decrypted.yaml) continue ;;
        */.sops.yaml)     continue ;;
    esac
    SECRET_FILES="$SECRET_FILES $f"
done

if [ -z "$SECRET_FILES" ]; then
    echo "WARN: No secret files found in $SECRETS_ENV_DIR — running command without secrets." >&2
    exec "$@"
fi

# ---------------------------------------------------------------------------
# Flatten: decrypt each file to dotenv, parse and export every KEY=VALUE
#
# Why not `source <(sops ...)`?
#   - Process substitution (<()) is a bashism, not POSIX.
#   - Writing to a tempfile and sourcing it is portable and survives MSYS2.
#
# Security: mktemp creates a 0600 file; we delete it in the EXIT trap.
# ---------------------------------------------------------------------------
TMP_ENV="$(mktemp)"
# Ensure cleanup even on error or SIGINT
trap 'rm -f "$TMP_ENV"' EXIT INT TERM

for f in $SECRET_FILES; do
    echo ">> Decrypting: $f" >&2

    # Decrypt to dotenv format into a temp accumulator.
    # sops exits non-zero on failure; set -e propagates it.
    "$SOPS" decrypt --output-type dotenv "$f" >> "$TMP_ENV" 2>/dev/null || {
        echo "ERROR: Failed to decrypt $f" >&2
        exit 1
    }
done

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|\#*) continue ;;
    esac

    key="${line%%=*}"
    raw_value="${line#*=}"

    case "$key" in
        *[!a-zA-Z0-9_]*|'') continue ;;
    esac

    case "$raw_value" in
        \'*\') raw_value="${raw_value#\'}" ; raw_value="${raw_value%\'}" ;;
        \"*\") raw_value="${raw_value#\"}" ; raw_value="${raw_value%\"}" ;;
    esac

    export "$key=$raw_value"
done < "$TMP_ENV"

rm -f "$TMP_ENV"
trap - EXIT INT TERM

exec "$@"
