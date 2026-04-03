#!/usr/bin/env sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/scripts/_lib.sh"

for tool in atmos terraform sops age-keygen; do
  find_bin "$tool" >/dev/null
done

printf 'All tools found.\n'
"$SCRIPTS_DIR/sops.sh" setup
