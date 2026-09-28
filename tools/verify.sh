#!/bin/bash
# LunaOs verification gate. Every check prints PASS or FAIL.
# Exits non-zero if any check fails.
set -u
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
ok()  { echo "PASS  $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }

# The ten applications the kernel embeds as its initial VFS image. The three
# LunaOs applications (free, init, wello) join this list when they are ported.
APPS="cat console hello ls moko redia shell soler taris tm"

# --- check 1: clean build, no errors, no warnings -----------------------
BUILD_LOG=$(mktemp)
if make clean >/dev/null 2>&1 && make >"$BUILD_LOG" 2>&1; then
  if grep -qE 'error:|warning:' "$BUILD_LOG"; then
    bad "1 clean build (nasm reported errors or warnings)"
    grep -E 'error:|warning:' "$BUILD_LOG" | head -5
  else
    ok "1 clean build, zero errors and warnings"
  fi
else
  bad "1 clean build (make exited non-zero)"
  tail -20 "$BUILD_LOG"
fi

# --- check 2: every artifact present and non-empty ----------------------
MISSING=""
for a in $APPS library kernel luna_stage2 bootsector boot luna_disk.raw; do
  [ -s "build/$a" ] || MISSING="$MISSING $a"
done
if [ -z "$MISSING" ]; then
  ok "2 all artifacts present and non-empty"
else
  bad "2 missing or empty artifacts:$MISSING"
fi

# --- checks 3 and 4: boot without crashing, and render a desktop --------
PPM=$(mktemp -u /tmp/opencode/verifyXXXX.ppm)
SOCK=$(mktemp -u /tmp/opencode/verifyXXXX.sock)
qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw \
  -m 16 -smp 2 -display none \
  -monitor "unix:$SOCK,server,nowait" -no-reboot >/dev/null 2>&1 &
QPID=$!
sleep 14

if kill -0 "$QPID" 2>/dev/null; then
  ok "3 QEMU alive after 14s (no triple fault, no panic loop)"
  python3 -c "
import socket
s = socket.socket(socket.AF_UNIX)
s.connect('$SOCK'); s.settimeout(5)
s.recv(65536)
s.sendall(b'screendump $PPM\n')
s.recv(65536)
s.close()" 2>/dev/null
  sleep 2
  python3 -c "
import sys
from collections import Counter
try:
    d = open('$PPM','rb').read().split(b'\n', 3)
    w, h = map(int, d[1].split())
    px = d[3]
except Exception as e:
    print('  no screendump:', e); sys.exit(1)
colors = len(Counter(px[i:i+3] for i in range(0, len(px), 3)))
print('  resolution %dx%d, %d distinct colors' % (w, h, colors))
sys.exit(0 if (w == 1280 and h == 720 and colors > 1) else 1)" \
    && ok "4 rendered a desktop at 1280x720 with more than one color" \
    || bad "4 did not render a usable desktop (blank or wrong resolution)"
else
  bad "3 QEMU died during boot"
  bad "4 no framebuffer to inspect (QEMU died)"
fi
kill "$QPID" 2>/dev/null
rm -f "$PPM" "$SOCK"

# --- check 8: no upstream project name or attribution in code ----------
HITS=$(git grep -liE 'cyjon|blackdev|adamczyk|blackend' -- '*.asm' 'Makefile' '*.sh' '*.bat' '*.bxrc' 2>/dev/null | wc -l)
if [ "$HITS" -eq 0 ]; then
  ok "8 no cyjon/blackdev/adamczyk in code, build, or scripts"
else
  bad "8 rebrand incomplete in $HITS file(s):"
  git grep -liE 'cyjon|blackdev|adamczyk|blackend' -- '*.asm' 'Makefile' '*.sh' '*.bat' '*.bxrc'
fi

# Checks 9 (no Polish characters) and 10 (no commented-out code) land with the
# comment cleanup and are appended here once the tree has been translated.

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
