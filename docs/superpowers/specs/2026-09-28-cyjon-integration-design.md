# LunaOs — Cyjon Integration Design

Date: 2026-09-28
Upstream: `https://github.com/CorruptedByCPU/Cyjon` @ `72a83091fa4c7f488e590147e4eaa85458a8d0ee`

## Purpose

Adopt the Cyjon codebase as the body of LunaOs. Cyjon is a 199-module, 29,523-line x86-64
assembly operating system that is a direct descendant of the same aidenOS ancestor LunaOs
was forked from, and it is a near-superset of LunaOs's 133-file, 12,167-line tree. Adopting it
is the only way to obtain the full upstream feature set.

After this work LunaOs contains every Cyjon subsystem, the project is named LunaOs
throughout, all code comments are in English, no commented-out code remains, documentation
covers every module, and the system boots to a rendered desktop in QEMU.

## Success criteria

1. `nasm` assembles every build target with zero errors and zero warnings.
2. QEMU boots `luna_disk.raw`, stays alive, and renders a desktop (screendump shows more than
   one distinct color).
3. All 13 applications are present on the disk image and load.
4. The three LunaOs-only applications (`free`, `init`, `wello`) run, with their
   `KERNEL_SERVICE_*` identifiers correctly remapped onto Cyjon's service table.
5. `kernel/debug.asm` is ported and its call site is reachable.
6. No source, build, or script file contains the strings `Cyjon`/`cyjon`, `blackdev`, or
   `Andrzej Adamczyk`. Upstream may be cited as provenance in `README.md` and in the
   historical design record under `docs/superpowers/`.
7. No tracked file contains commented-out code.
8. No `.asm` file contains Polish-language characters.
9. Every kernel-side module has a `docs/` entry.

## Non-goals

- Preserving Cyjon's identifier spelling where it is not user-visible. Upstream subsystem
  names are adopted as-is (see Decision 3).
- Bochs support beyond the upstream config files.
- Any feature not present in upstream and not already in LunaOs.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Strip upstream copyright/blackdev headers | Chosen by project owner. Recorded as a risk in Risks. |
| 2 | Project named LunaOs; `Cyjon` removed from all identifiers, strings, paths, prose | Requirement |
| 3 | Adopt `wm`, `gui`, `gc` names as-is | Upstream versions are newer than LunaOs's `desu`/`workbench_service`/`tresher` |
| 4 | Boot chain becomes `luna/bootsector.asm` + `luna/luna.asm` + `luna/*.asm` | Owner: "change into luna bootsector" |
| 5 | Port `free`, `init`, `wello` in addition to upstream's 10 apps | Owner decision |
| 6 | Keep `docs/` per-module `.txt` convention; cover every module | Owner decision |
| 7 | Reset tree to upstream structure, then layer ports as follow-up commits | Owner decision |
| 8 | Delete the 39 superseded LunaOs files outright; port 6 more back | Owner decision |

## Architecture

### Boot chain

LunaOs's multiboot path is removed. Upstream does not use multiboot: upstream's
`zero/kernel.asm` passes a bespoke structure to the kernel, and `zero/*.asm` performs
memory-map collection, graphics mode selection, protected-mode and long-mode transition, IDT
setup, PIC masking, and kernel loading from disk. Upstream's stage-2 loader is therefore
required in place of `luna/luna.asm`'s multiboot implementation.

```
luna/bootsector.asm   MBR, INT 13h, loads stage 2
  -> luna/luna.asm    (from upstream zero.asm)  graphics + PM + LM + IDT + PIC + disk load
    -> kernel.asm     64-bit kernel entry
```

Upstream's `zero.asm` becomes `luna/luna.asm`; `zero/*.asm` (11 files) becomes `luna/*.asm`;
`zero/driver/storage/ide.asm` becomes `luna/driver/storage/ide.asm`. `bootsector.asm` becomes
`luna/bootsector.asm`. Constants move into `luna/config.asm`. Upstream's `disk.asm` stays at the
repository root, retargeted to the new stage names.

Deleted as a consequence: `kernel/init/multiboot.asm`, `kernel/init/long_mode.asm`
(superseded by `luna/protected_mode.asm` and `luna/long_mode.asm`).

### Target tree

```
LunaOs/
  Makefile  README.md  LICENSE  config.asm  .gitignore
  luna/            bootsector.asm, luna.asm, config.asm, data.asm, graphics.asm,
                   protected_mode.asm, long_mode.asm, idt.asm, pic.asm, pit.asm,
                   kernel.asm, memory.asm, page.asm, driver/storage/ide.asm
  kernel.asm
  kernel/
    config.asm data.asm apic.asm idt.asm io_apic.asm exec.asm ipc.asm memory.asm
    page.asm panic.asm service.asm sleep.asm stream.asm task.asm thread.asm vfs.asm
    debug.asm                       <-- PORTED from LunaOs (upstream has no handler)
    header/    ipc library service stream task vfs wm
    init/      acpi ap apic boot data gdt idt ipc library memory network page ps2
               rtc serial services smp storage stream task vfs video
    library.asm
    library/   bit bresenham color input integer_to_string page_align_up
               page_from_size string_compare string_cut string_digits string_to_float
               string_to_integer string_trim string_word_next terminal value_to_size
               xorshift32 font font/header bosu bosu/header bosu/data terminal/header
    macro/     apic copy debug library lock
    driver/    pci ps2 rtc serial network/i82540em storage/ide
               storage/vfs/character_device
    service/   gc gui gui/{clock config data event init ipc ipc/wm taskbar}
               http tx network network/{arp checksum config data icmp tcp wrap}
               wm wm/{config cursor data event fill gfx/cursor.data init ipc
                     keyboard object panic service sleep zone}
  software/
    cat/ console/ hello.asm ls/ moko/ redia.asm shell/ soler/ taris/ tm/
    free/ init/ wello.asm           <-- PORTED from LunaOs
  fs/  etc/hostname  var/welcome.txt
  docs/  (per-module .txt, see Documentation)
  tools/  verify.sh                <-- NEW, boot smoke test
```

### Deleted LunaOs files (39)

Of 45 `.asm` files that exist in LunaOs but not upstream, 39 are deleted and 6 are ported
back (`kernel/debug.asm`, `software/free.asm`, `software/free/data.asm`,
`software/init.asm`, `software/init/data.asm`, `software/wello.asm`).

| Superseded by | Files removed |
|---|---|
| `kernel/service/wm/*` | `kernel/service/desu.asm`, `kernel/service/desu/{config,cursor,data,fill,init,keyboard,object,panic,sleep,zone}.asm` |
| `kernel/service/gui*` | `kernel/service/workbench_service.asm`, `kernel/service/workbench_service/{config,data,init}.asm` |
| `kernel/service/gc.asm` | `kernel/service/tresher.asm` |
| `kernel/library/font*` | `kernel/font/jetbrains.asm`, `kernel/font/setfont.asm`, `kernel/init/font.asm` |
| `kernel/library/*` | `library/bosu.asm`, `library/bosu/{config,font}.asm`, `library/{color,input,page_align_up,page_from_size,string_compare,string_cut,string_digits,string_to_integer,string_trim,string_word_next}.asm` |
| `luna/*` | `luna/luna.asm`, `luna/config.asm` (contents replaced, files removed) |
| `kernel.asm` (root) | `kernel/kernel.asm` |
| `zero/*` → `luna/*` | `kernel/init/multiboot.asm`, `kernel/init/long_mode.asm` |
| `kernel/library/terminal.asm` | `kernel/video.asm` |
| `kernel/panic.asm` | `kernel/init/panic.asm` (upstream wires panic directly) |

## Components

### 1. Upstream adoption

Copy 199 `.asm` modules from upstream at the pinned commit. Apply three transformations:

- **Rebrand.** `Cyjon`/`cyjon` → `LunaOs` in identifiers, user-visible strings, `%include`
  paths, and prose. Zero occurrences remain.
- **Header removal.** Delete the 5-line copyright/`blackdev`/`Adamczyk` block from each of
  the 199 files. Each file retains its `;---` section banners.
- **Comment translation.** Translate 180 files' Polish comments to English. Preserve meaning
  and section structure; do not paraphrase technical terms away from their upstream wording
  where a standard English term exists.

Result: a tree that is upstream's structure, LunaOs's name.

### 2. Rebrand of the boot stage

Beyond renaming, `luna/luna.asm` absorbs upstream `zero.asm`'s role. Upstream's
`STATIC_ZERO_*` constants become `STATIC_LUNA_*` in `luna/config.asm`, preserving upstream's
existing values. `disk.asm` becomes the disk-image assembler, retargeted to
`luna/bootsector.asm` and `luna/luna.asm`, and emits `build/luna_disk.raw`.

### 3. Ported LunaOs features

Three applications and one kernel module are ported onto the upstream base. These are the only
hand-written code in the integration; everything else is upstream.

#### `kernel/debug.asm`

Upstream ships `kernel/macro/debug.asm` (the logging macro) but **no handler**. LunaOs's
`kernel/debug.asm` implements the handler: a register dump covering `rflags`, `rax` through
`r15`, plus the faulting process name and PID. Port requires:

1. Copy the module, translating comments, dropping the copyright block.
2. Remap its string and label identifiers onto upstream's `KERNEL_*` naming.
3. Wire a call site into upstream's IDT exception path. Upstream's `kernel/idt.asm` and
   `kernel/panic.asm` are the integration points. This is the one place where the port is
   genuinely new code rather than a copy, and it must not regress upstream's panic behavior.

Acceptance: a fault in QEMU produces the register/PID dump rather than a bare panic.

#### `software/free/`, `software/init/`, `software/wello.asm`

LunaOs applications built against LunaOs's service table. Port requires remapping every
`KERNEL_SERVICE_*` constant they use onto upstream's `kernel/service.asm` table. Upstream's
table differs from LunaOs's, so this mapping is verified at runtime, not assumed:

- `free` calls `KERNEL_SERVICE_VIDEO_string`, `KERNEL_SERVICE_SYSTEM_memory`,
  `KERNEL_SERVICE_VIDEO_cursor`, `KERNEL_SERVICE_VIDEO_number`. Upstream has no
  `KERNEL_SERVICE_SYSTEM_memory`; equivalent memory-statistics access must be routed through
  upstream's existing service or its `tm/ram.asm` equivalent.
- `init` is LunaOs's first user process. Upstream's `kernel/init/services.asm` auto-starts
  services, so `init` may be redundant. It is ported per Decision 5; if it proves to be a
  no-op it is documented as such rather than silently dropped.
- `wello` prints one string. Mechanical port.

All three are added to the build and to the disk image, and are added to upstream's
`kernel/init/services.asm` auto-start list where applicable.

### 4. Build

`Makefile` replaces `make.sh`/`make.bat` with standard make targets, following the existing
LunaOs Makefile's style:

```
software (13) -> library -> kernel -> luna/luna.asm -> luna/bootsector.asm -> luna_disk.raw
```

Order matters: `library` is `incbin`'d by the kernel, the kernel by `luna.asm`, stage 2 by the
boot sector. `KERNEL_FILE_SIZE_bytes` and `ZERO_FILE_SIZE_bytes` are passed as `-d` defines
as upstream does. Targets: `all`, `run-qemu`, `qemu-smp-2`, `debug`, `clean`.

Upstream commits 21 build artifacts to git; these are added to `.gitignore` instead.
`build/.gitignore` is retained.

**Warning cleanup.** LunaOs's `kernel/macro/lock.asm` emits `lock` before `xchg`, which `nasm`
reports as `superfluous LOCK prefix on XCHG` at 9 call sites today. Upstream's `macro/lock.asm`
is adopted; the warning must be gone for criterion 1 to pass.

### 5. Documentation

Existing convention retained: one `.txt` per module, prose describing purpose, interface, and
dependencies, referenced from `README.md` tables.

135 kernel-side modules require documentation once the port lands (134 upstream kernel-side
modules plus the ported `kernel/debug.asm`). Of the 15 existing `docs/**/*.txt` files, 14 map
onto modules that survive the reorg and are rewritten; the 15th (`desu.txt`) is deleted with
`desu/` and replaced by a new `wm.txt`. That leaves **121 new `.txt` files**.

- **Rewrite** the 14 surviving files, three of which move with their module:
  `docs/config.txt` -> `config.asm`; `kernel/docs/kernel.txt` -> `docs/kernel.txt` (follows
  `kernel.asm` to the repository root); `library/docs/color.txt` -> `kernel/library/docs/color.txt`
  (follows `color.asm` under the kernel). The other 11 stay put: `kernel/docs/{data,exec,init,
  service,vfs,macro_lock}.txt`, `kernel/driver/docs/serial.txt`,
  `kernel/init/docs/{data,ps2,serial,vfs}.txt`.
- **Delete** `kernel/service/docs/desu.txt`.
- **Add** 121 new `.txt` files, one per remaining module:

  | Bucket | Modules | Already documented | New |
  |---|---|---|---|
  | `luna/*` | 14 | 0 | 14 |
  | `kernel/*.asm` | 20 | 5 (`data`, `exec`, `init`, `service`, `vfs`) | 15 |
  | `kernel/service/*` | 34 | 0 | 34 |
  | `kernel/library/*` | 23 | 1 (`color`) | 22 |
  | `kernel/init/*` | 22 | 4 (`data`, `ps2`, `serial`, `vfs`) | 18 |
  | `kernel/header/*` | 7 | 0 | 7 |
  | `kernel/driver/*` | 7 | 1 (`serial`) | 6 |
  | `kernel/macro/*` | 5 | 1 (`lock`) | 4 |
  | root (`config`, `disk`, `kernel`) | 3 | 2 (`config`, `kernel`) | 1 (`disk`) |
- **Software applications** are documented as a README table (13 apps), not per-module `.txt`,
  matching the existing convention where `shell.txt` lives under `kernel/service/docs/`.
- **`README.md`** rewritten in English: new title, feature set covering stream/gc/gui/wm/GC,
  boot-chain diagram, build and run instructions with the correct `-m 16 -smp 2` parameters,
  the full documentation tables, and the existing OSDev reference links.

## Data flow

Boot: BIOS -> `luna/bootsector.asm` (MBR) -> INT 13h loads `luna/luna.asm` -> memory map
(E820) + graphics mode -> protected mode -> long mode -> IDT -> load `kernel` from disk ->
jump to `kernel.asm` -> `kernel/init.asm` (ACPI, GDT, IDT, paging, memory, video, RTC, PS/2,
serial, storage, network, VFS, library, IPC, tasks, services) -> scheduler -> services auto-start
(`gui`, `wm`, `gc`, `tx`) -> desktop rendered to the framebuffer.

Applications reach the kernel only through `int KERNEL_SERVICE` with upstream's service
constants. This is the boundary the `free`/`init`/`wello` port must respect.

## Error handling

- **Build failure** — `make` stops on the first `nasm` error; no partial `build/luna_disk.raw`
  is produced.
- **Boot failure** — `tools/verify.sh` distinguishes three outcomes: QEMU process died
  (triple fault / panic loop), QEMU alive but screendump is a single color (blank or hung
  before graphics), QEMU alive with multi-color output (booted). The script exits non-zero on
  the first two.
- **Port failure** — if `free`/`init`/`wello` fail to remap a service constant, the symptom is
  a hang or an IPC error at runtime. `tools/verify.sh` runs each app explicitly rather than
  relying on auto-start, so the failure is attributable.

## Testing

`tools/verify.sh` is the single gate. Each check prints PASS or FAIL; the script exits
non-zero if any check fails.

| # | Check | Method |
|---|---|---|
| 1 | Clean build | `make clean && make`; assert exit 0 and no `error:` or `warning:` in output |
| 2 | All artifacts present | 13 software binaries, `library`, `kernel`, `luna` (stage 2), `bootsector`, `luna_disk.raw` all exist and are non-empty |
| 3 | Boots without crashing | QEMU with `-m 16 -smp 2 -no-reboot`, 15s, process still alive |
| 4 | Renders a desktop | monitor `screendump` -> PPM; assert >1 unique color, resolution 1280x720. Upstream baseline: 14 colors |
| 5 | Apps on disk | each of the 13 app binaries linked into the image and referenced by the exec path |
| 6 | Ported apps run | `free`, `init`, `wello` executed; assert no hang and expected output present |
| 7 | Debug handler | trigger a fault under QEMU; assert register/PID dump, not a bare panic |
| 8 | Rebrand clean | `grep -rniE 'cyjon\|blackdev\|adamczyk'` over tracked `*.asm`, `Makefile`, `*.sh`, `*.bat`, `*.bxrc` returns nothing. Excluded: `docs/superpowers/` (the historical design record, which cites upstream deliberately) and the provenance paragraph in `README.md` |
| 9 | No Polish | `grep -rlP '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]'` over `*.asm` returns nothing |
| 10 | No commented-out code | `grep -rnE '^\s*;\s*(mov|add|sub|cmp|jmp|call|ret|push|pop|int|lea|xor|test|inc|dec|nop|db|dw|dq|times|equ|%include)'` over `*.asm` returns nothing |
| 11 | Docs complete | every kernel-side module path has a `docs/` counterpart; `README.md` references each |

Checks 8-11 are exact greps, so "no commented-out code" and "no Polish" are gates rather than
intentions. Check 10 permits `;---` banners and prose comments while rejecting any line whose
comment body is an instruction, directive, or data definition.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Upstream is GPL-3.0; this repository declares MIT. Decision 1 removes the copyright headers, so the merged tree is a derivative work presented under an incompatible license. | **High — legal** | Recorded at the owner's explicit direction. Not resolvable by engineering. The owner's options are to relicense the repository to GPL-3.0, to obtain an exception from the upstream author, or to revert to a clean-room approach. |
| `kernel/debug.asm` call-site integration is new code against upstream's IDT path | Medium | Isolated in its own commit; check 7 verifies it independently |
| `free` has no upstream `KERNEL_SERVICE_SYSTEM_memory` equivalent | Medium | Check 6; if no equivalent exists, route through `tm/ram.asm`'s data path and document the deviation |
| `wm`/`gui`/`gc` rename breaks LunaOs's README and existing docs | Low | Documentation is rewritten wholesale in the same change set |
| 180-file comment translation may introduce subtle mistranslation of register or flag names | Low | Translation is constrained to prose; identifiers are never translated |
| Upstream's 2 MiB-era QEMU assumptions vs 16 MiB requirement | Low | Makefile and README pin `-m 16`; check 3 uses it |

## Commit sequence

| # | Commit | Contents |
|---|---|---|
| 1 | `feat: adopt upstream kernel structure as LunaOs` | Delete 39 superseded files; add rebranded 199-module tree with English comments |
| 2 | `feat(boot): rename boot chain into luna/` | `luna/bootsector.asm`, `luna/luna.asm`, `luna/*.asm`, disk image assembler |
| 3 | `feat(kernel): port debug handler` | `kernel/debug.asm` + IDT call site |
| 4 | `feat(software): port free, init, wello` | 3 LunaOs applications remapped to upstream's service table |
| 5 | `build: makefile, clean warnings, verify script` | `Makefile`, `.gitignore`, `tools/verify.sh` |
| 6 | `docs: rewrite and extend module documentation` | 14 rewrites, 1 deletion, 121 new `.txt`, `README.md` |
