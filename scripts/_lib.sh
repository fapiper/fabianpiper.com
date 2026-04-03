#!/usr/bin/env sh

SCRIPTS_DIR="$REPO_ROOT/scripts"
SECRETS_DIR="$REPO_ROOT/secrets"
AGE_KEY_FILE="$SECRETS_DIR/.sops.key"
SOPS_CONFIG=".sops.yaml"
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

find_bin() {
  _name="$1"
  if command -v "$_name" >/dev/null 2>&1; then echo "$_name"; return 0; fi
  if command -v "${_name}.exe" >/dev/null 2>&1; then echo "${_name}.exe"; return 0; fi
  printf 'ERROR: %s not found in PATH\n' "$_name" >&2
  return 1
}

