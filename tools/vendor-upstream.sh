#!/bin/bash
# Copies the pinned upstream tree into the LunaOs working tree.
# Run from the repository root. Idempotent.
set -euo pipefail

UPSTREAM=/tmp/opencode/cyjon
COMMIT=72a83091fa4c7f488e590147e4eaa85458a8d0ee

cd "$(dirname "$0")/.."

if [ ! -d "$UPSTREAM" ]; then
  git clone --quiet https://github.com/CorruptedByCPU/Cyjon.git "$UPSTREAM"
  git -C "$UPSTREAM" checkout --quiet "$COMMIT"
fi

# Assembly sources, constants, disk filesystem content, build script.
git -C "$UPSTREAM" ls-tree -r --name-only "$COMMIT" \
  | grep -E '(\.asm$|\.data$|^fs/|^make\.sh$)' \
  | while read -r f; do
      mkdir -p "$(dirname "$f")"
      cp "$UPSTREAM/$f" "$f"
    done

chmod +x make.sh
echo "vendored $(git -C "$UPSTREAM" ls-tree -r --name-only "$COMMIT" | grep -cE '\.asm$') assembly modules"
