#!/bin/bash
# Prints assembly source with every comment and blank line removed.
# Used to prove that a comment translation did not alter any code.
#
# A semicolon inside a double-quoted string is data, not a comment: the tree
# contains escape sequences such as "^[t1;__--]" whose tail would otherwise be
# cut off, which would hide a real code change from the diff.
#
# Usage: tools/strip-comments.sh FILE [FILE...]
set -uo pipefail
for f in "$@"; do
  awk '
    {
      out = ""; inq = 0
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "\"") inq = !inq
        if (c == ";" && !inq) break
        out = out c
      }
      sub(/[ \t]+$/, "", out)
      if (out ~ /[^ \t]/) print out
    }
  ' "$f"
done
exit 0
