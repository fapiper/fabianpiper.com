#!/usr/bin/env sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/scripts/_lib.sh"

ACTION="${1:-}"
ENV="${2:-}"

read_pk() {
    grep 'public key' "$AGE_KEY_FILE" | cut -d' ' -f4
}

case "$ACTION" in
    setup)
        mkdir -p "$SECRETS_DIR"
        if [ -f "$AGE_KEY_FILE" ]; then
            printf 'Age key already exists: %s\n' "$AGE_KEY_FILE"
        else
            age-keygen -o "$AGE_KEY_FILE"
        fi
        ;;
    init)
        [ -n "$ENV" ] || { printf 'Usage: sops.sh init <env>\n' >&2; exit 1; }
        PK="$(read_pk)"
        mkdir -p "$SECRETS_DIR/$ENV"
        cat > "$SECRETS_DIR/$ENV/$SOPS_CONFIG" <<EOF
creation_rules:
  - path_regex: '.*\.yaml$'
    age: $PK
EOF
        printf 'Initialized SOPS config for %s\n' "$ENV"
        ;;
    encrypt)
        [ -n "$ENV" ] || { printf 'Usage: sops.sh encrypt <env>\n' >&2; exit 1; }
        PK="$(read_pk)"
        for f in "$SECRETS_DIR/$ENV"/*.decrypted.yaml; do
            [ -f "$f" ] || continue
            out="${f%.decrypted.yaml}.yaml"
            sops --encrypt --age "$PK" --output "$out" "$f"
            printf 'Encrypted %s\n' "$out"
        done
        ;;
    decrypt)
        [ -n "$ENV" ] || { printf 'Usage: sops.sh decrypt <env>\n' >&2; exit 1; }
        for f in "$SECRETS_DIR/$ENV"/*.yaml; do
            [ -f "$f" ] || continue
            case "$f" in
                *.decrypted.yaml|*"$SOPS_CONFIG") continue ;;
            esac
            out="${f%.yaml}.decrypted.yaml"
            sops --decrypt "$f" > "$out"
            printf 'Decrypted to %s\n' "$out"
        done
        ;;
    *)
        printf 'Usage: %s {setup|init|encrypt|decrypt} [env]\n' "$0" >&2
        exit 1
        ;;
esac
