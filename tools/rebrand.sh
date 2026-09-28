#!/bin/bash
# Strips the upstream copyright block and rebrands "cyjon" to "LunaOs".
# Idempotent: re-running on an already-rebranded tree is a no-op.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Remove the 6-line copyright header, tolerating the TAB on line 6 and
#    trailing-whitespace variants found in 4 of the 199 files.
#    tail+mv preserves the existing line endings (12 of the 199 are CRLF).
for f in $(find . -name '*.asm' -not -path './build/*'); do
  if head -2 "$f" | grep -q 'Copyright (C) Andrzej Adamczyk'; then
    tail -n +7 "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

# 2. Rebrand the kernel's self-name.
sed -i 's/^\(%define\tKERNEL_name\t*\)"cyjon"/\1"LunaOs"/' kernel/config.asm

# 3. Rebrand the HTTP service banner string.
sed -i 's/db\t"Cyjon v"/db\t"LunaOs v"/' kernel/service/http.asm

# 4. Rebrand any residual occurrence in scripts and build files.
#    No-op on the current tree: make.sh never named the project.
sed -i 's/Cyjon/LunaOs/g; s/cyjon/luna_os/g' make.sh 2>/dev/null || true

# 5. Self-check: a sed that matches nothing is silent, so assert the result.
leftover=$(git grep -lIE 'cyjon|Cyjon|CYJON|adamczyk|Adamczyk|blackdev' -- '*.asm' | wc -l)
[ "$leftover" -eq 0 ] || { echo "rebrand: $leftover .asm file(s) still carry upstream names" >&2; exit 1; }
