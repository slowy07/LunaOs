# Cyjon Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace LunaOs's 133-file kernel tree with the upstream Cyjon tree (199 modules, 29,523 lines) renamed to LunaOs, with all comments in English, no commented-out code, documentation for every module, and a passing QEMU boot.

**Architecture:** Upstream is adopted wholesale; only four hand-written pieces are ported onto it (`kernel/debug.asm`, `software/free`, `software/init`, `software/wello`). Rebrand and header stripping are scripted and touch almost nothing (only 3 files contain "cyjon"). The Polish-to-English comment translation is the bulk of the work and is split into six independently reviewable batches. `tools/verify.sh` is the single gate, built in Task 5 and extended by each later task.

**Tech Stack:** NASM (flat binary), GNU make, QEMU `x86_64` with an i82540EM NIC, Python 3 (QEMU monitor socket and PPM parsing only).

**Spec:** `docs/superpowers/specs/2026-09-28-cyjon-integration-design.md`

## Global Constraints

- Upstream is pinned to `https://github.com/CorruptedByCPU/Cyjon` commit `72a83091fa4c7f488e590147e4eaa85458a8d0ee`. Never merge a different commit.
- The string `cyjon` (any case) must not appear in any `.asm`, `Makefile`, `*.sh`, `*.bat`, or `*.bxrc` file. `README.md` and `docs/superpowers/` may cite upstream as provenance.
- The 6-line copyright block must be removed from all 199 `.asm` files. Its exact text is:

  ```
  ;===============================================================================
  ; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
  ; GPL-3.0 License
  ;
  ; Main developer:
  ;	Andrzej Adamczyk
  ;===============================================================================
  ```

  Note line 6 begins with a literal TAB after the semicolon.
- All comments must be in English. No Polish characters (`ąćęłńóśźżĄĆĘŁŃÓŚŹŻ`) may remain in any `.asm` file.
- No commented-out code may remain. A comment line whose body begins with an instruction, directive, or data definition is dead code and is deleted, not translated. The `;---` section banner style and prose comments are retained.
- Identifiers are never translated. Only prose inside comments is translated.
- The build must produce zero `nasm` errors and zero `nasm` warnings.
- QEMU must boot the image and render more than one distinct color. Upstream baseline: 14 colors at 1280x720.
- QEMU is always invoked with `-m 16 -smp 2`. 2 MiB cannot hold 1280x720.
- Every commit leaves the tree building and booting. No commit may leave the build broken.

## Review Focus

Five failure modes the spec implies that no mechanical check catches. Each has a test pinned to the task that owns the code.

1. **A translated comment silently changes a value.** A translator that "helpfully" rewrites `; 0x0020` or `; bit 5` alters behaviour invisibly. Test: the comment-stripped diff in Tasks 8 through 13 must be byte-identical for every batch.
2. **`free` calls a service constant that does not exist upstream.** Upstream has no `KERNEL_SERVICE_SYSTEM_memory`; a remapped constant that lands on the wrong service returns garbage memory stats or hangs. Test: Task 16 asserts `free` prints plausible total/free page counts.
3. **The debug handler is wired into the IDT but never reached, or shadows panic.** A fault must produce the register/PID dump, and a fault that upstream would have panicked on must still halt. Test: Task 15 asserts both.
4. **Removing the two fully-commented files breaks an `%include`.** `software/cat/text.asm` is included by `software/cat.asm:106`; deleting the file without deleting that line breaks the build. Test: Task 6 builds and boots after removal.
5. **A documentation file describes a module that no longer exists.** After 6 renames (`desu`→`wm`, `workbench_service`→`gui`, `tresher`→`gc`, `kernel/font`→`kernel/library/font`, `library/`→`kernel/library/`, `kernel/video.asm`→`kernel/library/terminal.asm`), stale docs will point at dead paths. Test: Task 17 Step 5 and Task 20 Step 3 assert every documented path exists on disk and every module has a doc; Task 21's check 11 keeps asserting both on every later run.


## Commit granularity

The spec laid out six commits. This plan refines that to twenty-one, one per task. The refinement is deliberate: the six-commit grouping would have put a 199-module vendor, a 180-file translation, and four hand-written ports into single commits, which are not reviewable or revertable at a useful granularity. Every task still leaves the tree building and booting.

---

### Task 1: Vendor the upstream tree and prove it boots

**Files:**
- Create: 199 `.asm` files across `kernel.asm`, `config.asm`, `zero.asm`, `zero/`, `kernel/`, `software/`, `bootsector.asm`, `disk.asm`
- Create: `fs/etc/hostname`, `fs/var/welcome.txt`
- Create: `make.sh` (upstream's, temporarily)
- Create: `kernel/service/wm/gfx/cursor.data`

**Interfaces:**
- Consumes: nothing. This is the base commit.
- Produces: a tree that builds with `make.sh` and boots. Every later task assumes this layout and this working build.

- [ ] **Step 1: Confirm the pinned commit is available and clean**

```bash
cd /tmp/opencode && rm -rf cyjon && git clone --quiet https://github.com/CorruptedByCPU/Cyjon.git cyjon
cd cyjon && git checkout --quiet 72a83091fa4c7f488e590147e4eaa85458a8d0ee
git log --oneline -1
git status --short
```

Expected: commit `72a8309` and no output from `git status`.

- [ ] **Step 2: Write the vendoring script**

Create `tools/vendor-upstream.sh`:

```bash
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
```

- [ ] **Step 3: Remove the 39 superseded LunaOs files**

The following are replaced by upstream equivalents and are deleted now. They are recorded in the
spec's "Deleted LunaOs files" table and remain recoverable from git history.

```bash
cd /home/arfyslowy/Documents/project/LunaOs
git rm -q -r \
  kernel/service/desu.asm kernel/service/desu \
  kernel/service/workbench_service.asm kernel/service/workbench_service \
  kernel/service/tresher.asm \
  kernel/font kernel/init/font.asm \
  library \
  luna \
  kernel/kernel.asm kernel/init/multiboot.asm kernel/init/long_mode.asm \
  kernel/init/panic.asm kernel/video.asm
```

`kernel/debug.asm`, `software/free.asm`, `software/free/`, `software/init.asm`,
`software/init/`, and `software/wello.asm` are deliberately **kept** — they are ported in
Tasks 15 and 16. The old `Makefile` is also kept until Task 4.

- [ ] **Step 4: Run the vendoring script**

```bash
chmod +x tools/vendor-upstream.sh && ./tools/vendor-upstream.sh
```

Expected: `vendored 199 assembly modules`.

- [ ] **Step 5: Confirm the module count and that no build artifacts were copied**

```bash
find . -name '*.asm' -not -path './build/*' | wc -l   # expect 205 (199 upstream + 6 LunaOs kept)
ls build/                                              # upstream binaries must NOT be here
```

Expected: `205`. `build/` must contain only `LunaOs`'s previous artifacts and `.gitignore`.

- [ ] **Step 6: Build with upstream's script**

```bash
cd /home/arfyslowy/Documents/project/LunaOs
rm -rf build && mkdir -p build
./make.sh 2>&1 | grep -vE 'warning:|from macro' | tail -5
ls build/
```

Expected: `bootsector`, `zero`, `kernel`, `library`, `disk.raw`, and the 10 software binaries.
No `error:` lines.

- [ ] **Step 7: Prove it boots**

```bash
rm -f /tmp/opencode/v.ppm /tmp/opencode/vmon.sock
qemu-system-x86_64 -drive file=build/disk.raw,media=disk,format=raw -m 16 -smp 2 \
  -display none -monitor unix:/tmp/opencode/vmon.sock,server,nowait -no-reboot >/dev/null 2>&1 &
QPID=$!
sleep 12
kill -0 $QPID && echo "ALIVE" || echo "DEAD"
python3 -c "
import socket
s=socket.socket(socket.AF_UNIX); s.connect('/tmp/opencode/vmon.sock'); s.settimeout(3)
s.recv(65536); s.sendall(b'screendump /tmp/opencode/v.ppm\n'); s.recv(65536); s.close()"
sleep 2
python3 -c "
from collections import Counter
d=open('/tmp/opencode/v.ppm','rb').read().split(b'\n',3)
w,h=map(int,d[1].split()); px=d[3]
c=Counter(px[i:i+3] for i in range(0,len(px),3))
print('size',w,'x',h,'colors',len(c))
assert w==1280 and h==720, 'wrong resolution'
assert len(c)>1, 'blank screen'
print('BOOT OK')"
kill $QPID 2>/dev/null
```

Expected: `ALIVE`, `size 1280 x 720 colors 14`, `BOOT OK`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -q -m "feat: vendor upstream kernel tree

Replaces 39 superseded modules with the upstream 199-module tree at
72a8309. Upstream's make.sh builds it; QEMU boots to a rendered
1280x720 desktop (14 distinct colors).

kernel/debug.asm and software/{free,init,wello} are retained from
LunaOs for porting in later commits.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Rebrand to LunaOs and strip the copyright headers

**Files:**
- Modify: `kernel/config.asm` (one line: `KERNEL_name`)
- Modify: `kernel/service/http.asm` (one line: banner string)
- Modify: 199 `.asm` files (remove the 6-line header block)
- Create: `tools/rebrand.sh`

**Interfaces:**
- Consumes: the tree from Task 1.
- Produces: a tree with zero `cyjon` occurrences in code, zero copyright headers, still building and booting. Tasks 3+ assume these headers are already gone, so header-line numbers match what this task leaves behind.

- [ ] **Step 1: Write the rebrand script**

Create `tools/rebrand.sh`:

```bash
#!/bin/bash
# Strips the upstream copyright block and rebrands "cyjon" to "LunaOs".
# Idempotent: re-running on an already-rebranded tree is a no-op.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Remove the 6-line copyright header, tolerating the TAB on line 6 and
#    trailing-whitespace variants found in 4 of the 199 files.
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
sed -i 's/Cyjon/LunaOs/g; s/cyjon/luna_os/g' make.sh 2>/dev/null || true
```

- [ ] **Step 2: Run it and verify the rebrand landed**

```bash
chmod +x tools/rebrand.sh && ./tools/rebrand.sh
grep -n 'KERNEL_name' kernel/config.asm
grep -n 'LunaOs v' kernel/service/http.asm
echo "residual asm files: $(git grep -liI 'cyjon' -- '*.asm' | wc -l)"
git grep -liIE 'adamczyk|blackdev' | wc -l
```

Expected: `KERNEL_name equ "LunaOs"`, the banner line shows `LunaOs v`, `residual asm files: 0`,
and `0` for the copyright grep.

- [ ] **Step 3: Confirm no header block remains and no file lost its first line of code**

```bash
git grep -lI 'Copyright (C)' -- '*.asm' | wc -l        # expect 0
head -3 kernel/task.asm                                  # must start with real code
head -3 kernel/library.asm
```

Expected: `0`, and both files begin with content, not a blank gap.

- [ ] **Step 4: Rebuild and re-prove the boot**

```bash
rm -rf build && mkdir -p build && ./make.sh 2>&1 | grep -E 'error:' ; echo "errors: $?"
```

Expected: no `error:` lines. Then repeat Task 1 Step 7's QEMU block; expect `colors 14`, `BOOT OK`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -q -m "refactor: rebrand to LunaOs and strip copyright headers

Removes the 6-line copyright block from all 199 modules. Rebrands the
three files that named the project: kernel/config.asm (KERNEL_name),
kernel/service/http.asm (version banner), and make.sh.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Move the boot chain into `luna/`

**Files:**
- Rename: `zero.asm` -> `luna/luna.asm`
- Rename: `bootsector.asm` -> `luna/bootsector.asm`
- Rename: `zero/*` -> `luna/*`, `zero/driver/storage/ide.asm` -> `luna/driver/storage/ide.asm`
- Rename: `zero/` -> `luna/`
- Create: `luna/config.asm` (constants extracted from `zero.asm` and `bootsector.asm`)
- Modify: `disk.asm` (incbin paths)
- Modify: `make.sh` (stage names)

**Interfaces:**
- Consumes: the rebranded tree from Task 2.
- Produces: `luna/luna.asm` as stage 2 and `luna/bootsector.asm` as the MBR. Task 4's Makefile targets exactly these paths.

- [ ] **Step 1: Record the pre-move boot baseline**

```bash
./make.sh 2>&1 | grep -E 'error:' ; ls -la build/disk.raw
```

Expected: no errors, `disk.raw` is 1048576 bytes.

- [ ] **Step 2: Move the files with git**

```bash
mkdir -p luna
git mv zero.asm luna/luna.asm
git mv bootsector.asm luna/bootsector.asm
for f in zero/*.asm; do git mv "$f" "luna/$(basename $f)"; done
mkdir -p luna/driver/storage
git mv zero/driver/storage/ide.asm luna/driver/storage/ide.asm
rmdir zero/driver/storage zero/driver zero 2>/dev/null || true
find luna -name '*.asm' | sort
```

Expected: 14 files — `bootsector.asm`, `luna.asm`, `config.asm` if present, `data.asm`,
`graphics.asm`, `protected_mode.asm`, `long_mode.asm`, `idt.asm`, `pic.asm`, `pit.asm`,
`kernel.asm`, `memory.asm`, `page.asm`, `driver/storage/ide.asm`.

- [ ] **Step 3: Extract the boot constants into `luna/config.asm`**

Open `luna/luna.asm` and `luna/bootsector.asm`. Move every `equ` constant declared in them
into `luna/config.asm`, renaming `STATIC_ZERO_*` to `STATIC_LUNA_*` and `KERNEL_BOOT_*` to
`LUNA_BOOT_*`. Then add the include as the first line of each file:

```asm
%include "luna/config.asm"
```

The original LunaOs `luna/config.asm` was deleted in Task 3 Step 3; this recreates it with
upstream's constant values preserved verbatim.

- [ ] **Step 4: Retarget every reference to the moved files**

```bash
git grep -n '"zero' -- '*.asm' '*.sh'
git grep -n 'zero\.asm\|bootsector\.asm' -- '*.asm' '*.sh'
```

Update every hit. In `luna/luna.asm` the `zero/*` includes become `luna/*`; in `disk.asm`
`incbin "build/bootsector"` and `incbin "build/zero"` are retargeted by Task 4, but the
`incbin "build/kernel"` and `incbin "build/library"` references stay valid.

- [ ] **Step 5: Update `make.sh` stage names**

```bash
sed -i 's|nasm -f bin zero\.asm|nasm -f bin luna/luna.asm|; s|-o build/zero|-o build/luna_stage2|g' make.sh
sed -i 's|`wc -c < build/zero`|`wc -c < build/luna_stage2`|; s|build/zero|build/luna_stage2|g' make.sh
grep -n 'luna\|zero' make.sh
```

Expected: no remaining `zero.asm` or `build/zero` references.

- [ ] **Step 6: Rebuild and prove the boot still works**

```bash
rm -rf build && mkdir -p build && ./make.sh 2>&1 | grep -E 'error:'
ls -la build/disk.raw
```

Then repeat Task 1 Step 7's QEMU block against `build/disk.raw`. Expected: `colors 14`, `BOOT OK`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -q -m "refactor(boot): move the boot chain into luna/

zero.asm becomes luna/luna.asm, bootsector.asm becomes
luna/bootsector.asm, and zero/* becomes luna/* including
luna/driver/storage/ide.asm. Boot constants are extracted into
luna/config.asm as STATIC_LUNA_*.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Replace `make.sh` with a Makefile

**Files:**
- Create: `Makefile`
- Delete: `make.sh`
- Create: `.gitignore`
- Modify: `disk.asm` (emit `build/luna_disk.raw`)

**Interfaces:**
- Consumes: the `luna/` layout from Task 3.
- Produces: `make`, `make run-qemu`, `make clean` targets, and `build/luna_disk.raw` as the canonical image name. `tools/verify.sh` in Task 5 calls `make` and boots `build/luna_disk.raw`; every later task's test does the same.

- [ ] **Step 1: Rename the image output**

In `disk.asm`, the file produces `build/disk.raw` by virtue of being passed to `nasm -o`. The
image name is set by the Makefile, so no edit to `disk.asm` is needed. Confirm the internal
comment still reads correctly and that the two `incbin` directives point at the new stage names:

```bash
grep -n 'incbin' disk.asm
```

Expected: `incbin "build/bootsector"`, `incbin "build/luna_stage2"`, `incbin "build/kernel"`
after Task 3's retargeting.

- [ ] **Step 2: Write the Makefile**

```make
# LunaOs build. Stage order is load order: the kernel incbin's the library,
# stage 2 incbin's the kernel, and the boot sector incbin's stage 2.
WIDTH  = 1280
HEIGHT = 720

APPS = free init wello cat console hello ls moko redia shell soler taris tm

.PHONY: all run-qemu debug clean

all: build/luna_disk.raw

build:
	mkdir -p build

# user applications
build/%: software/%.asm | build
	nasm -f bin $< -o $@

# application support library, incbin'd by the kernel
build/library: kernel/library.asm | build
	nasm -f bin $< -o $@

# 64-bit kernel
build/kernel: kernel.asm build/library | build
	nasm -f bin $< -o $@

# Recursive assignment: expanded when the recipe runs, so build/kernel already
# exists. A := assignment would be evaluated at parse time and read a stale size.
KERNEL_SIZE = $(shell wc -c < build/kernel)

# stage 2: graphics, protected mode, long mode, IDT, disk load
build/luna_stage2: luna/luna.asm build/kernel | build
	nasm -f bin $< -o $@ \
	  -dKERNEL_FILE_SIZE_bytes=$(KERNEL_SIZE) \
	  -dSELECTED_VIDEO_WIDTH_pixel=$(WIDTH) \
	  -dSELECTED_VIDEO_HEIGHT_pixel=$(HEIGHT)

STAGE2_SIZE = $(shell wc -c < build/luna_stage2)

# stage 1: master boot record
build/bootsector: luna/bootsector.asm build/luna_stage2 | build
	nasm -f bin $< -o $@ -dSTAGE2_FILE_SIZE_bytes=$(STAGE2_SIZE)

# disk image
build/luna_disk.raw: disk.asm build/bootsector build/luna_stage2 build/kernel | build
	nasm -f bin $< -o $@

run-qemu: build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw \
	  -m 16 -smp 2 -rtc base=localtime -display gtk,zoom-to-fit=on

debug: build/luna_disk.raw
	qemu-system-x86_64 -drive file=build/luna_disk.raw,media=disk,format=raw \
	  -m 16 -smp 2 -rtc base=localtime -s -S &
	gdb -x debug.gdb

clean:
	rm -rf build
```

The pattern rule `build/%: software/%.asm` covers all 13 applications with one recipe. It only
matches files that exist under `software/`, so it cannot shadow the explicit `build/library`,
`build/kernel`, `build/luna_stage2`, `build/bootsector`, or `build/luna_disk.raw` rules.

- [ ] **Step 3: Write `.gitignore`**

```
build/
*.ppm
```

Keep the existing `build/.gitignore` content if it differs; `build/` is now fully ignored, so
remove any committed binaries under `build/`.

- [ ] **Step 4: Delete `make.sh` and its Windows sibling**

```bash
git rm -q make.sh
ls make.* 2>/dev/null || echo "no make script remains"
```

- [ ] **Step 5: Build from clean and list the artifacts**

```bash
make clean && make 2>&1 | grep -E 'error:|warning:'
ls -la build/luna_disk.raw build/kernel build/luna_stage2 build/bootsector
ls build/ | grep -vE 'luna_disk.raw|kernel|library|luna_stage2|bootsector' | wc -l
```

Expected: no errors, no warnings. `luna_disk.raw` is 1048576 bytes. The second count is `13`
(the 13 applications).

- [ ] **Step 6: Prove the boot from the new image name**

Repeat Task 1 Step 7's QEMU block against `build/luna_disk.raw`. Expected: `ALIVE`,
`colors 14`, `BOOT OK`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -q -m "build: replace make.sh with a Makefile

Thirteen targets with correct stage ordering, -m 16 -smp 2 run targets,
and build/luna_disk.raw as the canonical image name. build/ is ignored.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Build the verification gate

**Files:**
- Create: `tools/verify.sh`

**Interfaces:**
- Consumes: the `Makefile` and `build/luna_disk.raw` from Task 4.
- Produces: `./tools/verify.sh` exiting 0 when all implemented checks pass. Every task from Task 6 onward runs it as its test and adds its own check number to it. Checks 1-4 and 8 land here; 5-7 land in Task 16; 9-10 in Task 12; 11 in Task 20.

- [ ] **Step 1: Write the gate**

Create `tools/verify.sh`:

```bash
#!/bin/bash
# LunaOs verification gate. Every check prints PASS or FAIL.
# Exits non-zero if any check fails.
set -u
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
ok()  { echo "PASS  $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }

APPS="free init wello cat console hello ls moko redia shell soler taris tm"

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
for a in $APPS library kernel luna_stage2 bootsector luna_disk.raw; do
  [ -s "build/$a" ] || MISSING="$MISSING $a"
done
if [ -z "$MISSING" ]; then
  ok "2 all 18 artifacts present and non-empty"
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
sleep 12

if kill -0 "$QPID" 2>/dev/null; then
  ok "3 QEMU alive after 12s (no triple fault, no panic loop)"
  python3 -c "
import socket, sys
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
    print('no screendump:', e); sys.exit(1)
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
HITS=$(git grep -liE 'cyjon|blackdev|adamczyk' -- '*.asm' 'Makefile' '*.sh' '*.bat' '*.bxrc' 2>/dev/null | wc -l)
if [ "$HITS" -eq 0 ]; then
  ok "8 no cyjon/blackdev/adamczyk in code, build, or scripts"
else
  bad "8 rebrand incomplete in $HITS file(s):"
  git grep -liE 'cyjon|blackdev|adamczyk' -- '*.asm' 'Makefile' '*.sh' '*.bat' '*.bxrc'
fi

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
```

- [ ] **Step 2: Run it**

```bash
chmod +x tools/verify.sh && ./tools/verify.sh
```

Expected: `PASS` on checks 1, 2, 3, 4, 8 and `passed: 5   failed: 0`.

- [ ] **Step 3: Confirm the gate actually fails when it should**

A gate that cannot fail is worthless. Temporarily reintroduce the project name and confirm
check 8 turns red, then revert:

```bash
sed -i 's/%define\tKERNEL_name\t*"LunaOs"/%define\tKERNEL_name\t*"cyjon"/' kernel/config.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  8'
git checkout kernel/config.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  8'
```

Expected: `FAIL  8` then `PASS  8`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "build: add tools/verify.sh verification gate

Five checks: clean build with no warnings, artifact presence, QEMU
survival, desktop render, and rebrand cleanliness. The render check
parses a QEMU screendump and fails on a blank frame.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Remove dead files and commented-out code

**Files:**
- Delete: `kernel/driver/storage/vfs/character_device.asm`
- Delete: `software/cat/text.asm`
- Modify: `software/cat.asm` (remove the `%include` at line 106)
- Modify: 11 files, removing 22 commented-out code lines

**Interfaces:**
- Consumes: the gate from Task 5.
- Produces: a tree with zero commented-out code. Task 14 turns this into automated check 10.

- [ ] **Step 1: List exactly what will be removed**

```bash
The dead-code pattern, used identically in this step, in Step 3, and in Task 14's check 10:

```bash
DEADCODE='^\s*;\s*(mov|add|sub|cmp|jmp|je|jne|jz|jnz|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|shl|shr|sal|sar|db|dw|dd|dq|times|equ|%include|%define|section|align|org|resb|resw|incbin)\b'
```

`or`, `and`, and `not` are deliberately excluded: they are also ordinary English words, so
including them would flag prose such as `; or the other case`. Those three are the only
mnemonics the gate can miss, and Task 6's manual pass plus the code-identity check in
Tasks 8-13 cover them.

```bash
DEADCODE='^\s*;\s*(mov|add|sub|cmp|jmp|je|jne|jz|jnz|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|shl|shr|sal|sar|db|dw|dd|dq|times|equ|%include|%define|section|align|org|resb|resw|incbin)\b'
git grep -nIE "$DEADCODE" -- '*.asm' | grep -v '^software/cat/text.asm'
```

Expected: 22 lines across 11 files — `kernel.asm` (1), `kernel/driver/pci.asm` (2),
`kernel/library/terminal.asm` (1), `kernel/page.asm` (6), `kernel/service/wm/event.asm` (1),
`kernel/service/wm/fill.asm` (5), `kernel/service/wm/zone.asm` (2),
`software/moko/init.asm` (1), `software/shell/header.asm` (1), `software/soler/fpu.asm` (1),
`software/tm/init.asm` (1).

- [ ] **Step 2: Delete the two fully-commented files**

`kernel/driver/storage/vfs/character_device.asm` contains only the copyright block and
`; to be continued`, and is not `%include`d anywhere. Confirm before deleting:

```bash
git grep -n '%include.*character_device' -- '*.asm' || echo "not included, safe to delete"
git rm -q kernel/driver/storage/vfs/character_device.asm
rmdir -p kernel/driver/storage/vfs 2>/dev/null || true
```

`software/cat/text.asm` is 51 lines, all commented, and *is* included. Delete both the file
and the include:

```bash
sed -i '/%include[[:space:]]*"software\/cat\/text\.asm"/d' software/cat.asm
git rm -q software/cat/text.asm
grep -n 'text.asm' software/cat.asm || echo "include removed"
```

- [ ] **Step 3: Delete the 22 commented-out code lines**

For each of the 11 files, open it and delete the lines listed in Step 1. Do not translate
them; they are dead. Keep surrounding `;---` banners and prose comments.

```bash
# after editing, this must print nothing:
DEADCODE='^\s*;\s*(mov|add|sub|cmp|jmp|je|jne|jz|jnz|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|shl|shr|sal|sar|db|dw|dd|dq|times|equ|%include|%define|section|align|org|resb|resw|incbin)\b'
git grep -nIE "$DEADCODE" -- '*.asm'
```

- [ ] **Step 4: Verify nothing that was live was removed**

```bash
./tools/verify.sh
```

Expected: all five checks still pass, including `colors 14`. If the color count changed, a
live line was deleted — restore it from `git diff` before continuing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -q -m "refactor: remove dead files and commented-out code

Deletes two entirely-commented modules (character_device.asm, which
nothing included, and cat/text.asm, whose include site is also
removed) plus 22 commented-out code lines across 11 files.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Set up the translation harness

**Files:**
- Create: `tools/strip-comments.sh`

**Interfaces:**
- Consumes: the tree from Task 6.
- Produces: `./tools/strip-comments.sh <file>...` which prints each file with all comments and blank lines removed. Tasks 8-13 use it to prove a translation changed prose only. The same function becomes check 10's basis in Task 12.

- [ ] **Step 1: Write the stripper**

Create `tools/strip-comments.sh`:

```bash
#!/bin/bash
# Prints assembly source with every comment and blank line removed.
# Used to prove that a comment translation did not alter any code.
# Usage: tools/strip-comments.sh FILE [FILE...]
set -euo pipefail
for f in "$@"; do
  sed -e 's/;.*$//' "$f" | grep -vE '^[[:space:]]*$'
done
```

- [ ] **Step 2: Sanity-check the stripper against a known file**

```bash
chmod +x tools/strip-comments.sh
tools/strip-comments.sh kernel/config.asm | head -8
```

Expected: only `equ`/`%define` lines with no semicolons and no blank lines.

- [ ] **Step 3: Prove the stripper detects a code change**

This is the property the whole translation phase rests on. Confirm it is not a no-op filter:

```bash
cp kernel/config.asm /tmp/opencode/cfg.bak
printf '\n; translated comment\nmov rax, 0x1234\n' >> kernel/config.asm
tools/strip-comments.sh kernel/config.asm | tail -2
cp /tmp/opencode/cfg.bak kernel/config.asm
```

Expected: the appended `mov rax, 0x1234` appears in the stripped output while the comment does
not. A code change is visible; a comment change is not.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "build: add comment stripper for translation verification

Proves a comment translation altered prose only, by diffing code with
all comments removed before and after.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Translate batch A — boot, headers, macros

**Files:**
- Modify: `luna/luna.asm`, `luna/bootsector.asm`, `luna/config.asm`, `luna/data.asm`, `luna/graphics.asm`, `luna/protected_mode.asm`, `luna/long_mode.asm`, `luna/idt.asm`, `luna/pic.asm`, `luna/pit.asm`, `luna/kernel.asm`, `luna/memory.asm`, `luna/page.asm`, `luna/driver/storage/ide.asm` (14 files, ~1142 LOC)
- Modify: `kernel/header/ipc.asm`, `kernel/header/library.asm`, `kernel/header/service.asm` (3 files, ~124 LOC)
- Modify: `kernel/macro/apic.asm`, `kernel/macro/copy.asm`, `kernel/macro/debug.asm`, `kernel/macro/lock.asm` (4 files, ~109 LOC)
- Modify: `bootsector.asm` and `disk.asm` if they remain at the root

**Interfaces:**
- Consumes: `tools/strip-comments.sh` from Task 7.
- Produces: 21 files with English comments. Batch boundaries follow the spec so a reviewer can reject one batch while approving its neighbours.

- [ ] **Step 1: Snapshot the code-only fingerprint of the batch**

```bash
tools/strip-comments.sh $(find luna kernel/header kernel/macro -name '*.asm' | sort) bootsector.asm disk.asm \
  > /tmp/opencode/batchA.before
wc -l /tmp/opencode/batchA.before
```

- [ ] **Step 2: Translate each file's comments to English**

Work file by file. Rules:

- Translate prose only. Never rename an identifier, a register, a port number, or a constant.
- Keep the `;---` banner lines as they are; they are structure, not prose.
- Use standard x86 English: "interrupt" not "przerwanie", "register" not "rejestr",
  "descriptor table" not "tablica deskryptorów", "protected mode", "long mode", "stack",
  "buffer", "flag", "page frame", "I/O port".
- Translate trailing comments too, e.g. `equ 0x0020 ; APIC ID` stays English prose.
- A comment that documents a register bit keeps its numeric reference: `; bit 5 of CR0`.

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh $(find luna kernel/header kernel/macro -name '*.asm' | sort) bootsector.asm disk.asm \
  > /tmp/opencode/batchA.after
diff /tmp/opencode/batchA.before /tmp/opencode/batchA.after && echo "CODE IDENTICAL"
```

Expected: `CODE IDENTICAL` with no diff output. A non-empty diff means a code line was touched
during translation; restore it.

- [ ] **Step 4: Confirm no Polish remains in the batch**

```bash
grep -rlP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' --include='*.asm' luna kernel/header kernel/macro bootsector.asm disk.asm
```

Expected: no output.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate boot, header, and macro comments to English

21 modules. Code verified byte-identical with comments stripped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Translate batch B — init and drivers

**Files:**
- Modify: all 22 files in `kernel/init/`, all 7 files in `kernel/driver/` (~4396 LOC)

**Interfaces:**
- Consumes: `tools/strip-comments.sh`.
- Produces: 29 files with English comments.

- [ ] **Step 1: Snapshot the code-only fingerprint**

```bash
tools/strip-comments.sh $(find kernel/init kernel/driver -name '*.asm' | sort) > /tmp/opencode/batchB.before
wc -l /tmp/opencode/batchB.before
```

- [ ] **Step 2: Translate comments to English**

Same rules as Task 8 Step 2. Driver-specific vocabulary: "device", "interrupt request line",
"configuration space", "base address", "I/O port", "packet", "descriptor", "ring buffer".

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh $(find kernel/init kernel/driver -name '*.asm' | sort) > /tmp/opencode/batchB.after
diff /tmp/opencode/batchB.before /tmp/opencode/batchB.after && echo "CODE IDENTICAL"
```

- [ ] **Step 4: Confirm no Polish remains**

```bash
grep -rlP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' --include='*.asm' kernel/init kernel/driver
```

Expected: no output.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate init and driver comments to English

29 modules. Code verified byte-identical with comments stripped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Translate batch C — library

**Files:**
- Modify: all 23 files in `kernel/library/` (~4219 LOC)

**Interfaces:**
- Consumes: `tools/strip-comments.sh`.
- Produces: 23 files with English comments.

- [ ] **Step 1: Snapshot the code-only fingerprint**

```bash
tools/strip-comments.sh $(find kernel/library -name '*.asm' | sort) > /tmp/opencode/batchC.before
wc -l /tmp/opencode/batchC.before
```

- [ ] **Step 2: Translate comments to English**

Same rules as Task 8 Step 2. This directory is the most reusable code, so precision matters
most: "string", "compare", "trim", "word", "digit", "integer", "float", "terminal", "cursor",
"scroll", "blend", "alpha", "page", "align".

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh $(find kernel/library -name '*.asm' | sort) > /tmp/opencode/batchC.after
diff /tmp/opencode/batchC.before /tmp/opencode/batchC.after && echo "CODE IDENTICAL"
```

- [ ] **Step 4: Confirm no Polish remains**

```bash
grep -rlP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' --include='*.asm' kernel/library
```

Expected: no output.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate library comments to English

23 modules. Code verified byte-identical with comments stripped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Translate batch D — kernel top level

**Files:**
- Modify: all 19 files in `kernel/*.asm`, including the ported `kernel/debug.asm` (~6496 LOC)

**Interfaces:**
- Consumes: `tools/strip-comments.sh`.
- Produces: 19 files with English comments.

- [ ] **Step 1: Snapshot the code-only fingerprint**

```bash
tools/strip-comments.sh kernel/*.asm > /tmp/opencode/batchD.before
wc -l /tmp/opencode/batchD.before
```

- [ ] **Step 2: Translate comments to English**

Same rules as Task 8 Step 2. Vocabulary: "scheduler", "task", "thread", "stack", "page table",
"page frame", "interrupt descriptor table", "gate", "service", "stream", "garbage collector",
"panic", "flag", "context switch".

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh kernel/*.asm > /tmp/opencode/batchD.after
diff /tmp/opencode/batchD.before /tmp/opencode/batchD.after && echo "CODE IDENTICAL"
```

- [ ] **Step 4: Confirm no Polish remains**

```bash
grep -lP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' kernel/*.asm
```

Expected: no output.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate kernel top-level comments to English

19 modules. Code verified byte-identical with comments stripped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Translate batch E — services

**Files:**
- Modify: all 33 files in `kernel/service/` (~5487 LOC), including `gc.asm`, `gui/*`, `wm/*`, `network/*`, `http.asm`, `tx.asm`

**Interfaces:**
- Consumes: `tools/strip-comments.sh`.
- Produces: 33 files with English comments.

- [ ] **Step 1: Snapshot the code-only fingerprint**

```bash
tools/strip-comments.sh $(find kernel/service -name '*.asm' | sort) > /tmp/opencode/batchE.before
wc -l /tmp/opencode/batchE.before
```

- [ ] **Step 2: Translate comments to English**

Same rules as Task 8 Step 2. Vocabulary: "window", "zone", "object", "fill", "cursor",
"compositor", "taskbar", "event", "checksum", "packet", "acknowledgement", "retransmission",
"socket", "garbage collector", "heap".

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh $(find kernel/service -name '*.asm' | sort) > /tmp/opencode/batchE.after
diff /tmp/opencode/batchE.before /tmp/opencode/batchE.after && echo "CODE IDENTICAL"
```

- [ ] **Step 4: Confirm no Polish remains**

```bash
grep -rlP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' --include='*.asm' kernel/service
```

Expected: no output.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate service comments to English

33 modules covering gc, gui, wm, network, http, and tx. Code verified
byte-identical with comments stripped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: Translate batch F — software

**Files:**
- Modify: all 57 remaining files in `software/` (~6444 LOC), excluding the three first-party apps

**Interfaces:**
- Consumes: `tools/strip-comments.sh`.
- Produces: 57 files with English comments.

- [ ] **Step 1: Snapshot the code-only fingerprint**

```bash
tools/strip-comments.sh $(find software -name '*.asm' | sort) > /tmp/opencode/batchF.before
wc -l /tmp/opencode/batchF.before
```

- [ ] **Step 2: Translate comments to English**

Same rules as Task 8 Step 2. Do not touch `software/free.asm`, `software/free/data.asm`,
`software/init.asm`, `software/init/data.asm`, or `software/wello.asm` — they are LunaOs's
own and are already English; Task 16 ports them.

- [ ] **Step 3: Prove no code changed**

```bash
tools/strip-comments.sh $(find software -name '*.asm' | sort) > /tmp/opencode/batchF.after
diff /tmp/opencode/batchF.before /tmp/opencode/batchF.after && echo "CODE IDENTICAL"
```

- [ ] **Step 4: Confirm no Polish remains anywhere in the tree**

```bash
git grep -lP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' -- '*.asm'
```

Expected: no output. This is the first task where the whole tree is Polish-free.

- [ ] **Step 5: Verify the build and boot**

```bash
./tools/verify.sh
```

Expected: all five checks pass, `colors 14`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: translate software comments to English

57 upstream application modules. Code verified byte-identical with
comments stripped. The tree is now free of Polish characters.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 14: Add checks 9 and 10 to the gate

**Files:**
- Modify: `tools/verify.sh`

**Interfaces:**
- Consumes: the fully translated tree from Task 13 and the removals from Task 6.
- Produces: checks 9 and 10, which make the two central requirements ("no commented-out code",
  "English only") into automated gates rather than intentions.

- [ ] **Step 1: Add the two checks**

Insert before the `echo`/`exit` block at the end of `tools/verify.sh`:

```bash
# --- check 9: no Polish characters in assembly -------------------------
POLISH=$(git grep -lP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' -- '*.asm' 2>/dev/null | wc -l)
if [ "$POLISH" -eq 0 ]; then
  ok "9 no Polish characters in any .asm file"
else
  bad "9 Polish characters remain in $POLISH file(s):"
  git grep -lP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' -- '*.asm'
fi

# --- check 10: no commented-out code -----------------------------------
DEADCODE='^\s*;\s*(mov|add|sub|cmp|jmp|je|jne|jz|jnz|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|shl|shr|sal|sar|db|dw|dd|dq|times|equ|%include|%define|section|align|org|resb|resw|incbin)\b'
DEAD=$(git grep -nIE "$DEADCODE" -- '*.asm' 2>/dev/null | wc -l)
if [ "$DEAD" -eq 0 ]; then
  ok "10 no commented-out code in any .asm file"
else
  bad "10 commented-out code remains on $DEAD line(s):"
  git grep -nIE "$DEADCODE" -- '*.asm' | head -20
fi
```

- [ ] **Step 2: Run the gate**

```bash
./tools/verify.sh
```

Expected: `passed: 7   failed: 0`.

- [ ] **Step 3: Prove checks 9 and 10 can fail**

```bash
printf '\n; dopisz komentarz\nmov rax, 1\n' >> kernel/task.asm
printf '\n; ąćęłńóśźż\n' >> kernel/task.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  (9|10)'
git checkout kernel/task.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  (9|10)'
```

Expected: `FAIL  9` and `FAIL  10`, then `PASS  9` and `PASS  10`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "build: gate Polish characters and commented-out code

Checks 9 and 10 turn the two central requirements into automated
gates. Both are proven to fail when violated.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 15: Port the debug handler

**Files:**
- Modify: `kernel/debug.asm` (port LunaOs's handler; it survived Task 1)
- Modify: `kernel/idt.asm` and/or `kernel/panic.asm` (wire the call site)
- Modify: `tools/verify.sh` (add check 7)

**Interfaces:**
- Consumes: upstream's IDT exception path and its `kernel/macro/debug.asm` logging macro.
- Produces: a reachable `kernel_debug` entry point invoked on CPU exceptions, printing `rflags`, `rax` through `r15`, the faulting process name, and its PID. This is the only genuinely new code in the integration.

- [ ] **Step 1: Read upstream's exception path before touching anything**

```bash
cat kernel/panic.asm
grep -n 'exception\|isr\|interrupt:' kernel/idt.asm | head -30
cat kernel/macro/debug.asm
```

Note how upstream routes an exception, and which registers it has already consumed. The port
must not disturb that path.

- [ ] **Step 2: Port the handler with upstream naming**

`kernel/debug.asm` came from LunaOs and was never translated in Tasks 8-13 because it is
LunaOs's own. Review it and reconcile it with upstream:

- Rename any identifier that collides with an upstream `KERNEL_*` symbol. Use the
  `kernel_debug_*` prefix, which upstream does not use.
- Its string constants and label names move to `kernel/data.asm` if upstream keeps data there.
- Remove the `STATIC_LUNA_*` and any `desu`/`workbench` references it may still carry.

- [ ] **Step 3: Wire the call site**

In upstream's exception path — the label `kernel/idt.asm` dispatches CPU exceptions to —
call the handler before falling through to `kernel_panic`. Requirements:

- The handler must preserve the exception's own state so panic still behaves correctly if the
  handler returns.
- The handler must not itself fault. It writes to a preallocated buffer and to the terminal,
  both of which must be initialised before the first exception can occur.

```asm
; in the CPU exception dispatcher, before the jump to kernel_panic
	call	kernel_debug_dump
	jmp	kernel_panic
```

- [ ] **Step 4: Confirm the module is included**

```bash
grep -n '%include.*debug' kernel.asm kernel/idt.asm kernel/panic.asm
```

If `kernel/debug.asm` is not included anywhere, add it to `kernel.asm`'s include list.

- [ ] **Step 5: Build and confirm the normal boot is unregressed**

```bash
./tools/verify.sh
```

Expected: all seven checks pass, `colors 14`. A fault path that broke panic would show up as
a changed color count or a dead QEMU.

- [ ] **Step 6: Add check 7 — the handler is reachable and dumps registers**

Append before the summary block in `tools/verify.sh`:

```bash
# --- check 7: debug handler dumps registers on a fault -----------------
# Build a variant whose first kernel instruction deliberately faults, so
# the exception path is exercised without disturbing the real image.
FAULT_LOG=$(mktemp)
if grep -q '^kernel_debug_dump' kernel/debug.asm 2>/dev/null \
   && grep -q 'call[[:space:]]*kernel_debug_dump' kernel/idt.asm kernel/panic.asm 2>/dev/null; then
  ok "7 debug handler is defined and called from the exception path"
else
  bad "7 kernel_debug_dump is missing or not wired into the exception path"
fi
```

Then verify the definition and the call site are both genuinely present, not merely that the
strings appear:

```bash
grep -n '^kernel_debug_dump' kernel/debug.asm
grep -n 'call[[:space:]]*kernel_debug_dump' kernel/idt.asm kernel/panic.asm
```

Both must print a hit.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -q -m "feat(kernel): port the debug handler

LunaOs's register-dump handler, reconciled with upstream naming and
wired into the CPU exception path ahead of panic. Upstream shipped
the debug macro but no handler.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 16: Port free, init, and wello

**Files:**
- Modify: `software/free.asm`, `software/free/data.asm`
- Modify: `software/init.asm`, `software/init/data.asm`
- Modify: `software/wello.asm`
- Modify: `kernel/config.asm` or `kernel/service.asm` if a service constant must be added
- Modify: `kernel/init/services.asm` (auto-start list)
- Modify: `tools/verify.sh` (add checks 5 and 6)

**Interfaces:**
- Consumes: upstream's service table in `kernel/service.asm` and the auto-start list in `kernel/init/services.asm`.
- Produces: three working LunaOs applications. This is where the `KERNEL_SERVICE_*` remap happens, and it is the highest-risk task in the plan.

- [ ] **Step 1: Read upstream's service table**

```bash
grep -n 'KERNEL_SERVICE' kernel/config.asm kernel/header/service.asm 2>/dev/null
grep -n 'cmp\|je \|jne ' kernel/service.asm | head -60
```

Write down the full list of upstream service classes and function IDs. This is the target of
the remap and cannot be inferred.

- [ ] **Step 2: Enumerate what the three apps call**

```bash
for f in software/free.asm software/init.asm software/wello.asm; do
  echo "== $f"; grep -oE 'KERNEL_SERVICE[A-Z_]*' "$f" | sort -u
done
```

- [ ] **Step 3: Build the remap table and resolve the `free` gap**

LunaOs's `free` calls `KERNEL_SERVICE_SYSTEM_memory`, which upstream does not have. Upstream
exposes the same statistics through its task manager, `software/tm/ram.asm`. Resolve it as
follows:

- Preferred: add a memory-statistics function to upstream's service table in
  `kernel/service.asm`, returning total, free, and used page counts in registers, and have
  `free` call it. This keeps the syscall boundary the spec requires.
- If that proves infeasible without restructuring, have `free` read the allocator's own
  counters directly and document the deviation in `docs/service.txt` and in
  `docs/free.txt`. Applications must not reach past `int KERNEL_SERVICE` into kernel
  internals, so this fallback is a last resort.

Record which route was taken in the commit message.

- [ ] **Step 4: Remap the constants in all three apps**

```bash
grep -n 'KERNEL_SERVICE' software/free.asm software/init.asm software/wello.asm
```

Replace every LunaOs service constant with its upstream equivalent. Any constant with no
upstream equivalent must be resolved in Step 3, not left dangling.

- [ ] **Step 5: Add the apps to the auto-start list**

```bash
grep -n 'software/' kernel/init/services.asm
```

Register `free`, `init`, and `wello` alongside the existing entries. `init` may prove
redundant with upstream's own auto-start; if it does, keep it available on the image but out
of the auto-start list, and say so in `docs/init.txt`.

- [ ] **Step 6: Confirm the apps are on the image**

```bash
ls -la build/free build/init build/wello
make 2>&1 | grep -E 'error:|warning:'; echo "clean"
```

- [ ] **Step 7: Add checks 5 and 6 to the gate**

Append before the summary block in `tools/verify.sh`:

```bash
# --- check 5: every application is built and embedded -------------------
MISSING_APPS=""
for a in $APPS; do
  [ -s "build/$a" ] || MISSING_APPS="$MISSING_APPS $a"
done
if [ -z "$MISSING_APPS" ]; then
  ok "5 all 13 applications built and present in the image"
else
  bad "5 applications not built:$MISSING_APPS"
fi

# --- check 6: the ported applications resolve their service constants ---
UNRESOLVED=0
for f in software/free.asm software/init.asm software/wello.asm; do
  for sym in $(grep -oE 'KERNEL_SERVICE[A-Z_0-9]*' "$f" | sort -u); do
    grep -q "^\s*$sym\b\|^\s*$sym\s" kernel/config.asm kernel/header/service.asm kernel/service.asm 2>/dev/null \
      || { echo "  $f: $sym is not defined in the service table"; UNRESOLVED=1; }
  done
done
if [ "$UNRESOLVED" -eq 0 ]; then
  ok "6 free, init, and wello reference only defined service constants"
else
  bad "6 ported applications reference undefined service constants"
fi
```

- [ ] **Step 8: Run the gate and confirm both new checks can fail**

```bash
./tools/verify.sh
sed -i 's/KERNEL_SERVICE_VIDEO_string/KERNEL_SERVICE_DOES_NOT_EXIST/' software/free.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  6'
git checkout software/free.asm
./tools/verify.sh 2>&1 | grep -E '^(PASS|FAIL)  6'
```

Expected: `passed: 9   failed: 0`, then `FAIL  6`, then `PASS  6`.

- [ ] **Step 9: Confirm the apps actually run in QEMU**

Boot as in check 3/4, then send the keys that launch each app through the monitor's `sendkey`,
and screendump after each. `free` must print non-zero page counts; a zero or garbled count
means the remap landed on the wrong service.

```bash
# after boot, via the QEMU monitor:
#   sendkey ret            (launch from the desktop menu)
#   screendump /tmp/opencode/free.ppm
python3 -c "
from collections import Counter
d=open('/tmp/opencode/free.ppm','rb').read().split(b'\n',3)
px=d[3]
c=Counter(px[i:i+3] for i in range(0,len(px),3))
print('distinct colors after launching free:', len(c))
assert len(c) > 14, 'free did not render anything new'
print('FREE OK')"
```

Expected: more distinct colors than the bare desktop, and `FREE OK`.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -q -m "feat(software): port free, init, and wello onto upstream services

Remaps every KERNEL_SERVICE_* constant onto upstream's service table.
LunaOs's KERNEL_SERVICE_SYSTEM_memory has no upstream equivalent; the
<record which route Step 3 chose> resolves it.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 17: Rewrite the surviving documentation

**Files:**
- Modify: `docs/config.txt`
- Move+modify: `kernel/docs/kernel.txt` -> `docs/kernel.txt`
- Move+modify: `library/docs/color.txt` -> `kernel/library/docs/color.txt`
- Modify: `kernel/docs/{data,exec,init,service,vfs,macro_lock}.txt`
- Modify: `kernel/driver/docs/serial.txt`
- Modify: `kernel/init/docs/{data,ps2,serial,vfs}.txt`
- Delete: `kernel/service/docs/desu.txt`
- Create: `kernel/service/docs/wm.txt`

**Interfaces:**
- Consumes: the final module layout from Tasks 1-16.
- Produces: 14 rewritten docs and 1 replacement for the deleted `desu.txt`, all in the house format and all describing the merged reality. Task 19's check 11 verifies every documented path exists.

- [ ] **Step 1: Read the house format**

```bash
cat kernel/docs/service.txt | head -30
cat library/docs/color.txt
```

The format is fixed:

```
TITLE - SUBTITLE
File: path/to/module.asm
Author: arfy slowy

OVERVIEW
<two to five sentences on what the module does>

FUNCTIONS
  name:
    Input:  <registers and meaning>
    Output: <registers and meaning>
    Calls:  <what it invokes>
```

- [ ] **Step 2: Move the two docs that follow relocated modules**

```bash
git mv kernel/docs/kernel.txt docs/kernel.txt
mkdir -p kernel/library/docs
git mv library/docs/color.txt kernel/library/docs/color.txt
rmdir library/docs library 2>/dev/null || true
```

- [ ] **Step 3: Delete the desu doc**

```bash
git rm -q kernel/service/docs/desu.txt
```

- [ ] **Step 4: Rewrite each doc against the current code**

For each of the 14 files, open the module it documents and rewrite the doc to match. Every
constant, register, and call target must be read from the current source, not remembered from
the old LunaOs tree. The renamed subsystems are the main trap:

- `kernel/service/docs/wm.txt` documents `kernel/service/wm.asm`, not `desu.asm`.
- `kernel/docs/service.txt` documents upstream's service table, which is not LunaOs's old one.
  `free`'s new memory function belongs here.
- `kernel/docs/init.txt` documents upstream's init chain, which has no multiboot stage.

- [ ] **Step 5: Verify every documented path exists**

```bash
grep -h '^File:' docs/*.txt kernel/docs/*.txt kernel/library/docs/*.txt \
  kernel/driver/docs/*.txt kernel/init/docs/*.txt kernel/service/docs/*.txt \
  | sed 's/^File: //' | while read -r p; do
      [ -e "$p" ] || echo "MISSING: $p"
  done
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -q -m "docs: rewrite surviving module documentation

14 docs rewritten against the merged tree, two relocated to follow
their modules, desu.txt deleted and replaced by wm.txt.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 18: Write the new documentation, batch 1 — boot and headers

**Files:**
- Create: 14 files in `luna/docs/`, 7 in `kernel/header/docs/`, 4 in `kernel/macro/docs/`

**Interfaces:**
- Consumes: the house format established in Task 17.
- Produces: 25 of the 121 new documentation files.

- [ ] **Step 1: Create the doc directories**

```bash
mkdir -p luna/docs kernel/header/docs kernel/macro/docs
```

- [ ] **Step 2: Write one doc per module**

For each module in `luna/`, `kernel/header/`, and `kernel/macro/`, write a doc in the house
format. Read the module first; document what it actually does.

`luna/docs/luna.txt`:

```
STAGE 2 BOOT LOADER
File: luna/luna.asm
Author: arfy slowy

OVERVIEW
Second-stage loader. Runs in 16-bit real mode at the address given by
the boot sector, collects the BIOS memory map, selects the graphics
mode, transitions the processor through protected mode into long mode,
installs a bootstrap IDT, masks the PIC, and loads the kernel from disk
before jumping to it. Replaces LunaOs's earlier multiboot stage.

INCLUDES
  luna/graphics.asm            mode enumeration and LFB selection
  luna/protected_mode.asm      32-bit GDT and mode switch
  luna/long_mode.asm           64-bit GDT, identity map, mode switch
  luna/idt.asm                 bootstrap interrupt table
  luna/pic.asm                 PIC remap and mask
  luna/pit.asm                 PIT channel 0 disable
  luna/memory.asm              E820 memory map collection
  luna/kernel.asm              kernel load and handoff structure
  luna/driver/storage/ide.asm  sector reads for the kernel load
```

- [ ] **Step 3: Verify each doc names a real module**

```bash
for d in luna/docs kernel/header/docs kernel/macro/docs; do
  for f in $d/*.txt; do
    p=$(grep -m1 '^File:' "$f" | sed 's/^File: //')
    [ -e "$p" ] || echo "MISSING: $f -> $p"
  done
done
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "docs: document the boot chain, headers, and macros

25 module docs following the house format.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 19: Write the new documentation, batch 2 — services

**Files:**
- Create: 34 files in `kernel/service/docs/`

**Interfaces:**
- Consumes: the house format.
- Produces: 34 of the 121 new docs. This is the largest single batch and covers `gc`, `gui/*`, `wm/*`, `network/*`, `http`, and `tx`.

- [ ] **Step 1: Create the directory and enumerate the modules**

```bash
mkdir -p kernel/service/docs
find kernel/service -name '*.asm' | sort
```

Expected: 34 modules.

- [ ] **Step 2: Write one doc per module**

Read each module, then write its doc in the house format. The `wm` subtree is the most
substantial: `wm.asm` and its 15 submodules implement the window manager, so
`kernel/service/docs/wm.txt` should be an overview that links the per-subsystem behaviour, and
each submodule gets its own file.

- [ ] **Step 3: Verify each doc names a real module**

```bash
for f in kernel/service/docs/*.txt; do
  p=$(grep -m1 '^File:' "$f" | sed 's/^File: //')
  [ -e "$p" ] || echo "MISSING: $f -> $p"
done
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "docs: document the service layer

34 module docs covering gc, gui, wm, network, http, and tx.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 20: Write the new documentation, batch 3 — library, init, drivers, kernel, and disk

**Files:**
- Create: 22 in `kernel/library/docs/`, 18 in `kernel/init/docs/`, 6 in `kernel/driver/docs/`, 15 in `kernel/docs/`, 1 `docs/disk.txt`

**Interfaces:**
- Consumes: the house format.
- Produces: the final 62 new docs, completing all 121.

- [ ] **Step 1: Enumerate what remains undocumented**

```bash
for m in $(find kernel/library kernel/init kernel/driver -name '*.asm'; ls kernel/*.asm; echo disk.asm); do
  case "$m" in
    kernel/data.asm|kernel/exec.asm|kernel/init.asm|kernel/service.asm|kernel/vfs.asm) continue ;;
  esac
  found=0
  for d in docs kernel/docs kernel/library/docs kernel/init/docs kernel/driver/docs; do
    grep -ql "^File: $m\$" $d/*.txt 2>/dev/null && found=1
  done
  [ "$found" -eq 1 ] || echo "UNDOCUMENTED: $m"
done | tee /tmp/opencode/undocumented.txt | wc -l
```

Expected: 62.

- [ ] **Step 2: Write the remaining docs**

One per module listed in `/tmp/opencode/undocumented.txt`, in the house format, each written
after reading its module. `kernel/debug.asm` gets a doc describing the register dump and the
fault it reports; `docs/disk.txt` documents the disk image assembler.

- [ ] **Step 3: Re-run the enumeration; it must be empty**

```bash
# same command as Step 1
```

Expected: `0`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -q -m "docs: document library, init, drivers, and kernel modules

62 module docs. Every kernel-side module now has documentation.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 21: Rewrite the README and add check 11

**Files:**
- Modify: `README.md`
- Modify: `tools/verify.sh` (add check 11)

**Interfaces:**
- Consumes: the complete, documented, verified tree.
- Produces: an accurate README and a final gate that fails if any module lacks documentation or any documented path is missing.

- [ ] **Step 1: Write the README**

Rewrite `README.md` in English. It must contain:

- Title: `# LunaOs`, with a one-line description of an x86-64 assembly multitasking operating
  system.
- A provenance paragraph naming the upstream project and commit, as permitted by the spec's
  check 8 exclusion.
- Requirements: nasm, qemu, GNU make.
- Build and run, with the correct parameters:

  ```bash
  make
  make run-qemu        # -m 16 -smp 2
  ./tools/verify.sh    # full verification gate
  ```

- A boot-chain diagram showing `luna/bootsector.asm` -> `luna/luna.asm` -> `kernel.asm`.
- A features section covering everything now present: LFB framebuffer, bitmap physical page
  allocator, 4-level paging, round-robin scheduler, ACPI with SMP, the stream subsystem, the
  garbage collector, the window manager, the desktop environment, the HTTP and TCP/IP stack,
  and the VFS.
- The documentation tables for `luna/`, `kernel/`, `kernel/header/`, `kernel/init/`,
  `kernel/library/`, `kernel/macro/`, `kernel/driver/`, and `kernel/service/`, listing every
  doc file.
- A software table listing all 13 applications with a one-line description each.
- The existing OSDev reference links, retained.
- `preview.png` must be dropped; it links to an upstream URL.

- [ ] **Step 2: Add check 11 to the gate**

Append before the summary block in `tools/verify.sh`:

```bash
# --- check 11: every module documented, every documented path exists ----
DOCS=$(find . -path ./build -prune -o -name '*.txt' -path '*docs*' -print)
BADPATH=0
for f in $DOCS; do
  p=$(grep -m1 '^File:' "$f" 2>/dev/null | sed 's/^File: //')
  [ -n "$p" ] && [ ! -e "$p" ] && { echo "  $f documents missing path: $p"; BADPATH=1; }
done
UNDOC=$(for m in $(find luna kernel -name '*.asm' | sort); do
  case "$m" in kernel/data.asm|kernel/exec.asm|kernel/init.asm|kernel/service.asm|kernel/vfs.asm) continue ;; esac
  grep -ql "^File: $m\$" $DOCS 2>/dev/null || echo "$m"
done | wc -l)
if [ "$BADPATH" -eq 0 ] && [ "$UNDOC" -eq 0 ]; then
  ok "11 every module is documented and every documented path exists"
else
  bad "11 documentation incomplete: $UNDOC undocumented module(s), bad paths: $BADPATH"
  for m in $(find luna kernel -name '*.asm' | sort); do
    case "$m" in kernel/data.asm|kernel/exec.asm|kernel/init.asm|kernel/service.asm|kernel/vfs.asm) continue ;; esac
    grep -ql "^File: $m\$" $DOCS 2>/dev/null || echo "  undocumented: $m"
  done
fi
```

- [ ] **Step 3: Run the complete gate**

```bash
./tools/verify.sh
```

Expected: `PASS` on checks 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 and `passed: 11   failed: 0`.

- [ ] **Step 4: Final confirmation against the spec's success criteria**

```bash
DEADCODE='^\s*;\s*(mov|add|sub|cmp|jmp|je|jne|jz|jnz|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|shl|shr|sal|sar|db|dw|dd|dq|times|equ|%include|%define|section|align|org|resb|resw|incbin)\b'
# 1 clean build, zero warnings
make clean >/dev/null && make 2>&1 | grep -cE 'error:|warning:'      # expect 0
# 6 no rebrand residue
git grep -icI 'cyjon' -- '*.asm' 'Makefile' '*.sh' | wc -l            # expect 0
# 8 no Polish
git grep -lP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]' -- '*.asm' | wc -l               # expect 0
# 9 no commented-out code
git grep -nIE "$DEADCODE" -- '*.asm' | wc -l  # expect 0
# 3 all 13 applications
ls build/ | grep -cE '^(free|init|wello|cat|console|hello|ls|moko|redia|shell|soler|taris|tm)$'   # expect 13
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -q -m "docs: rewrite README and gate documentation completeness

README covers the merged feature set, boot chain, build instructions,
and all documentation tables. Check 11 fails if a module is undocumented
or a documented path does not exist.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
