# LunaOs

Multitasking operating system written in x86-64 assembly (formerly aidenOS). Features LFB framebuffer video, bitmap-based memory allocator, 4-level paging, round-robin scheduler, ACPI (RSDT/XSDT) with SMP support, and a network-enabled interactive shell.

## Requirements

- nasm
- qemu

## Building & Running

```sh
make          # builds build/luna_disk.raw
make run-qemu # builds and boots it in QEMU (16 MiB RAM, 2 CPUs, 1280x720)
make debug    # builds and starts QEMU paused, waiting for gdb
```

The build is driven by the Makefile: the boot sector, stage 2, kernel, support
library, and every application under `software/` are assembled with nasm and
packed into one 1 MiB disk image.

## Documentation

Per-module docs live in a `docs/` directory next to the code they describe.

### Root
- `docs/config.txt`  Global constants (page sizes, shifts, ASCII, colors)

### Kernel (`kernel/docs/`)
| File | Description |
|------|-------------|
| `kernel.txt` | Main kernel module |
| `init.txt` | Initialization chain |
| `data.txt` | Static data tables and string constants |
| `vfs.txt` | Virtual file system |
| `service.txt` | Service (syscall) dispatcher |
| `exec.txt` | Process execution |
| `macro_lock.txt` | Semaphore lock macro |

### Kernel Init (`kernel/init/docs/`)
| File | Description |
|------|-------------|
| `vfs.txt` | Initial VFS layout and embedded file records |
| `data.txt` | Static definitions used during init |
| `ps2.txt` | PS/2 mouse + keyboard initialization |
| `serial.txt` | COM1 serial port initialization |

### Kernel Services (`kernel/service/docs/`)
| File | Description |
|------|-------------|
| `desu.txt` | Desktop environment service (compositor, window management, mouse cursor) |

### Drivers (`kernel/driver/docs/`)
| File | Description |
|------|-------------|
| `serial.txt` | COM1 serial driver (115200 baud, 8N1, FIFO, string send) |

## Applications

The kernel mounts these applications under `/bin` as its initial VFS image:

| App | Path |
|-----|------|
| calculator | `/bin/calculator` |
| cat | `/bin/cat` |
| console | `/bin/console` |
| hello | `/bin/hello` |
| ls | `/bin/ls` |
| moko | `/bin/moko` |
| redia | `/bin/redia` |
| shell | `/bin/shell` |
| tetris | `/bin/tetris` |
| tm | `/bin/tm` |

`/etc/hostname` and `/var/welcome.txt` complete the initial file system.


## Key Systems

| System | Description |
|--------|-------------|
| **Video** | LFB framebuffer (32bpp, resolution read from multiboot, defaults 640x480), bitmap font rendering, cursor with nesting lock, SIMD-accelerated scrolling via `kernel_memory_copy` |
| **Paging** | 4-level page tables (PML4 → PDPT → PD → PT), 4 KB / 2 MB pages |
| **Memory** | Bitmap-based physical page allocator, SIMD-accelerated memory copy (`macro_copy`, 256 B/iter, prefetchnta + movdqa + movntdq) |
| **ACPI** | RSDP v1/v2 detection, RSDT (32-bit) and XSDT (64-bit) support, MADT parsing for LAPIC/IO-APIC enumeration |
| **Scheduling** | Round-robin scheduler driven by RTC at 1024 Hz, per-task flags (active, closed, service, processing, secured, thread) |
| **APIC** | Local APIC for timer interrupts, IO-APIC for device interrupt routing |
| **SMP** | Multi-processor boot via 16-bit real mode trampoline (`boot.asm`), AP wake through IPI, per-CPU GDT TSS entries |
| **Drivers** | PS/2 keyboard (scan codes, shift/capslock) + mouse (3-byte packet parsing, signed/unsigned movement, screen bounds clamping), RTC, PCI enumeration, IDE ATA/ATAPI, Intel 82540EM Gigabit Ethernet |
| **IPC** | Inter-process communication primitives |
| **Font** | Bitmap font glyph data loaded from `kernel/font/jetbrains.asm`, font name displayed at boot |
| **Services** | Task reaper (tresher) + desktop environment (desu) + workbench — started at boot |
| **Color** | ARGB alpha blending (`library_color_alpha`) and alpha inversion (`library_color_alpha_invert`) |

## References

| System | OSDev Wiki |
|--------|-----------|
| **x86-64 Long Mode** | [wiki.osdev.org/x86-64](https://wiki.osdev.org/x86-64)  64-bit mode init, CPU modes |
| **Multiboot** | [wiki.osdev.org/Multiboot](https://wiki.osdev.org/Multiboot)  Bootloader protocol, framebuffer info |
| **LFB Framebuffer** | [wiki.osdev.org/Drawing_In_a_Linear_Framebuffer](https://wiki.osdev.org/Drawing_In_a_Linear_Framebuffer)  Pixel-based video output |
| **VGA Fonts** | [wiki.osdev.org/VGA_Fonts](https://wiki.osdev.org/VGA_Fonts)  Bitmap font rendering in graphics mode |
| **ACPI** | [wiki.osdev.org/ACPI](https://wiki.osdev.org/ACPI)  RSDP, RSDT, XSDT, MADT table parsing |
| **APIC / IO-APIC** | [wiki.osdev.org/APIC](https://wiki.osdev.org/APIC)  Local APIC, IO-APIC, LVT, interrupt routing |
| **APIC Timer** | [wiki.osdev.org/APIC_timer](https://wiki.osdev.org/APIC_timer)  One-shot and periodic timer modes |
| **Paging (x86-64)** | [wiki.osdev.org/Paging](https://wiki.osdev.org/Paging)  4-level paging, PML4, PDPT, PD, PT |
| **Page Frame Allocation** | [wiki.osdev.org/Page_Frame_Allocation](https://wiki.osdev.org/Page_Frame_Allocation)  Bitmap-based physical allocator |
| **GDT** | [wiki.osdev.org/GDT_Tutorial](https://wiki.osdev.org/GDT_Tutorial)  Global Descriptor Table setup |
| **IDT** | [wiki.osdev.org/IDT](https://wiki.osdev.org/IDT)  Interrupt Descriptor Table, gates, vectors |
| **RTC / CMOS** | [wiki.osdev.org/RTC](https://wiki.osdev.org/RTC)  Real-time clock periodic interrupt (1024 Hz) |
| **SMP** | [wiki.osdev.org/SMP](https://wiki.osdev.org/SMP)  Symmetric multiprocessing, AP boot sequence |
| **IPI** | [wiki.osdev.org/IPI](https://wiki.osdev.org/IPI)  Inter-processor interrupts, APIC IPI delivery |
| **Real Mode** | [wiki.osdev.org/Real_Mode](https://wiki.osdev.org/Real_Mode)  16-bit real mode addressing and BIOS |
| **Protected Mode** | [wiki.osdev.org/Protected_Mode](https://wiki.osdev.org/Protected_Mode)  32-bit protected mode, GDT, segment protection |
| **PS/2 Keyboard** | [wiki.osdev.org/PS/2_Keyboard](https://wiki.osdev.org/PS/2_Keyboard)  Scan codes, port communication |
| **PCI** | [wiki.osdev.org/PCI](https://wiki.osdev.org/PCI)  PCI bus enumeration, configuration space |
| **Intel 8254x (NIC)** | [wiki.osdev.org/Intel_8254x](https://wiki.osdev.org/Intel_8254x)  Gigabit Ethernet driver interface |
| **Round-Robin Scheduler** | [wiki.osdev.org/Scheduling_Algorithms](https://wiki.osdev.org/Scheduling_Algorithms)  Scheduling theory, context switching |
| **Context Switching** | [wiki.osdev.org/Context_Switching](https://wiki.osdev.org/Context_Switching)  Save/restore state, TSS, IRETQ |
| **SSE / SIMD** | [wiki.osdev.org/SSE](https://wiki.osdev.org/SSE)  Streaming SIMD Extensions, movdqa, movntdq, prefetchnta |
| **IPC** | [wiki.osdev.org/Inter_Process_Communication](https://wiki.osdev.org/Inter_Process_Communication)  Message passing, shared memory |
| **VFS** | [wiki.osdev.org/VFS](https://wiki.osdev.org/VFS)  Virtual file system design and inode structures |
