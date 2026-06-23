# LunaOs

Multitasking operating system written in x86-64 assembly (formerly aidenOS). Features LFB framebuffer video, bitmap-based memory allocator, 4-level paging, round-robin scheduler, ACPI (RSDT/XSDT) with SMP support, and a network-enabled interactive shell.

## Requirements

- nasm
- qemu

## Building & Running

```asm
nasm -f bin kernel/init/boot.asm -o build/boot
nasm -f bin kernel/kernel.asm -o build/kernel
nasm -f bin luna/luna.asm -o build/luna.raw
qemu-system-x86_64 -drive file=build/luna.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime
```

## Documentation

### Root
- `docs/config.txt`  Global constants (page sizes, shifts, colors, ASCII)

### Kernel (`kernel/docs/`)
| File | Description |
|------|-------------|
| `kernel.txt` | Main kernel module |
| `config.txt` | Kernel configuration constants |
| `init.txt` | Initialization chain |
| `data.txt` | GDT, TSS, IDT headers, string constants |
| `video.txt` | LFB framebuffer video output |
| `memory.txt` | Bitmap-based page allocator + SIMD copy |
| `page.txt` | 4-level page tables and virtual memory |
| `idt.txt` | Interrupt Descriptor Table management |
| `task.txt` | Task scheduler |
| `thread.txt` | Thread management |
| `panic.txt` | Panic handler |
| `apic.txt` | Local APIC |
| `io_apic.txt` | IO-APIC |
| `ipc.txt` | Inter-process communication |
| `macro_close.txt` | Semaphore lock macro |
| `macro_apic.txt` | APIC ID macro |
| `macro_debug.txt` | Debug logging macro |
| `macro_copy.txt` | SIMD 256-byte memory copy macro |

### Kernel Init (`kernel/init/docs/`)
| File | Description |
|------|-------------|
| `long_mode.txt` | 32-bit to 64-bit transition |
| `multiboot.txt` | Multiboot header |
| `video.txt` | Framebuffer initialization (banner + resolution display) |
| `font.txt` | Font name display |
| `memory.txt` | Physical memory map setup (RAM size display) |
| `acpi.txt` | ACPI RSDP/RSDT/XSDT/MADT parsing |
| `page.txt` | Virtual memory setup |
| `gdt.txt` | GDT initialization |
| `idt.txt` | IDT initialization |
| `rtc.txt` | RTC timer setup (1024 Hz, sti enabled here) |
| `task.txt` | Scheduler startup |
| `ipc.txt` | IPC initialization |
| `panic.txt` | Panic handler setup |
| `data.txt` | Data/strings initialization |

### Kernel Services (`kernel/service/docs/`)
| File | Description |
|------|-------------|
| `shell.txt` | Interactive shell loop |
| `prompt.txt` | Command dispatch (clear, ip, etc.) |
| `data.txt` | Shell strings and cache buffer |
| `config.txt` | Shell configuration |
| `network.txt` | Network service (7 sub-files: config, data, checksum, arp, icmp, tcp, wrap) |
| `http.txt` | HTTP server service (port 80, IPC receive loop) |
| `tx.txt` | Network transmit service |
| `tresher.txt` | Task reaper service |

### Drivers (`kernel/driver/`)
| File | Description |
|------|-------------|
| `driver_docs.txt` | RTC driver |
| `ide.txt` | IDE ATA/ATAPI storage driver |
| `ps2.txt` | PS/2 keyboard/mouse (interrupt flow, scan codes, I/O ports) |
| `pci.txt` | PCI enumeration |
| `network/i82540em.txt` | Intel 82540EM Gigabit Ethernet |

### Library (`library/docs/`)
| File | Description |
|------|-------------|
| `page_align_up.txt` | Page alignment utility |
| `page_from_size.txt` | Size to page count conversion |
| `string_digits.txt` | String digit validation |
| `string_cut.txt` | String trimming |
| `string_to_integer.txt` | ASCII to integer conversion |


## Boot Process

```
+------------------+
|   BIOS/UEFI     |
+------------------+
        |
        v
+------------------+
|    Bootloader    |
|   (GRUB/QEMU)   |
+------------------+
        |
        v
+------------------+
| kernel/kernel.asm|
|   (32-bit mode)  |
+------------------+
        |
        v
+------------------+
| Long Mode Setup  |
| kernel/init/     |
|  long_mode.asm   |
+------------------+
        |
        v
+------------------+
|  64-bit Mode     |
|  Kernel Init     |
+------------------+
        |
        v
+------------------+
| SMP AP Boot      |
| boot.asm ->      |
| 16-bit -> 32-bit |
| -> kernel entry  |
+------------------+
```

## Kernel Initialization Sequence

```
+------------------------------+
|   init.asm entry (32-bit)    |
+------------------------------+
              |
              v
+------------------------------+
|   SMP check                  |
|   BSP ? continue : ap.asm   |
+------------------------------+
              |
              v
+------------------------------+
|   long_mode.asm -> 64-bit    |
|   (GDT, paging, long mode)  |
+------------------------------+
              |
              v
+------------------------------+
|   panic.asm / data.asm       |
|   multiboot.asm              |
|   + apic.asm (early detect)  |
+------------------------------+
              |
              v
+------------------------------+
|   kernel_init                |
+------------------------------+
              |
              v
+------------------------------+
|   video.asm  -> Framebuffer  |
|   (banner "LunaOS v1.90"     |
|    + resolution display)     |
+------------------------------+
              |
              v
+------------------------------+
|   font.asm  -> Font name     |
|   (display current font)     |
+------------------------------+
              |
              v
+------------------------------+
|   memory.asm -> Page bitmap  |
|   (parse multiboot mem map   |
|    + RAM size display)       |
+------------------------------+
              |
              v
+------------------------------+
|   acpi.asm  -> RSDT / XSDT   |
|   (MADT, LAPIC, IO-APIC)     |
+------------------------------+
              |
              v
+------------------------------+
|   page.asm -> Page tables    |
|   (PML4 -> PDPT -> PD -> PT) |
+------------------------------+
              |
              v
+------------------------------+
|   gdt.asm  -> GDT reload     |
|   (TSS for ring 0 stacks)    |
+------------------------------+
              |
              v
+------------------------------+
|   idt.asm  -> IDT load       |
|   (exception + IRQ vectors)  |
+------------------------------+
              |
              v
+------------------------------+
|   rtc.asm  -> Timer 1024 Hz  |
|   (interrupts enabled here)  |
+------------------------------+
              |
              v
+------------------------------+
|   ps2.asm  -> Kbd/Mouse init |
|   (IRQ1/IRQ12)               |
+------------------------------+
              |
              v
+------------------------------+
|   ipc.asm  -> IPC pool       |
+------------------------------+
              |
              v
+------------------------------+
|   vfs.asm  -> VFS init       |
|   (/dev directory created)   |
+------------------------------+
              |
              v
+------------------------------+
|   storage.asm -> PCI IDE init|
|   (SRST reset, enumerate,    |
|    create /dev/hd{a-d} knots,|
|    display size)             |
+------------------------------+
              |
              v
+------------------------------+
|   network.asm -> NIC detect  |
|   (PCI scan for i82540EM)    |
+------------------------------+
              |
              v
+------------------------------+
|   task.asm -> Scheduler init |
|   (idle task, kernel task)   |
+------------------------------+
              |
              v
+------------------------------+
|   services.asm               |
|   (tresher, tx, network,     |
|    HTTP, shell)              |
+------------------------------+
              |
              v
+------------------------------+
|   kernel_init_apic           |
|   Enable timer IRQ via LAPIC |
|   Set TICR = DRIVER_RTC_Hz  |
|   Send EOI                   |
|   sti (enable interrupts)   |
+------------------------------+
              |
              v
+------------------------------+
|   smp.asm -> AP boot         |
|   Send INIT IPI to all APs   |
|   Wait 10ms                  |
|   Send STARTUP IPI (vec 8)   |
|   APs boot via boot.asm      |
|   16-bit -> 32-bit -> kernel |
+------------------------------+
              |
              v
+------------------------------+
|   Wait for all APs           |
|   kernel_init_ap_count ==    |
|   kernel_apic_count          |
+------------------------------+
              |
              v
+------------------------------+
|   "Made By - Arfy Slowy"     |
|   kernel_init_semaphore = 0  |
|   (signals services to run)  |
+------------------------------+
              |
              v
+------------------------------+
|   clean:                     |
|   Free init code pages       |
|   via kernel_memory_release  |
+------------------------------+
```

## Process Flow Diagrams

### Task Scheduler (Round-Robin)

```
+-------------------+
|   RTC Interrupt   |
|    (1024 Hz)      |
+-------------------+
        |
        v
+-------------------+
| kernel_task()     |
| Save Current Task |
|   State (RSP,CR3) |
+-------------------+
        |
        v
+-------------------+
| Find Next Secured |
|     Task (FLAG)   |
+-------------------+
        |
        v
    +-------+-------+
    |  Found Task?  |
    +-------+-------+
        |           |
       Yes          No
        |           |
        v           v
+----------------+  +-----------------+
| Switch Context |  | Search Next     |
| (RSP,CR3,FXR)  |  | Block in Queue  |
+----------------+  +-----------------+
        |                  |
        v                  v
+----------------+  +-----------------+
| Load New Task  |  | Allocate Block  |
| Restore State  |  | if Needed       |
+----------------+  +-----------------+
        |                  |
        +--------+---------+
                 |
                 v
        +-----------------+
        |   iretq         |
        | Resume Task     |
        +-----------------+
```

### Memory Allocation

```
+-------------------------+
| kernel_memory_alloc(N)  |
+-------------------------+
            |
            v
+-------------------------+
| Search bitmap for       |
| contiguous free pages   |
+-------------------------+
            |
            v
    +-------------------+
    |  Block Found?     |
    +-------------------+
        |           |
       Yes          No
        |           |
        v           v
+----------------+  +-----------------+
| BTR to mark    |  | Return error    |
| pages as used  |  | (carry flag)    |
+----------------+  +-----------------+
        |
        v
+-------------------------+
| Return virtual address  |
| page_index << 12 + BASE |
+-------------------------+
```

### SIMD Memory Copy

```
+-------------------------+
| kernel_memory_copy()    |
+-------------------------+
            |
            v
+-------------------------+
| RCX /= 256 (iterations) |
+-------------------------+
            |
            v
+-------------------------+
|   .loop:                |
| prefetchnta [rsi+256..] |
| movdqa 16 XMM regs      |
| movntdq to [rdi]        |
+-------------------------+
            |
            v
+-------------------------+
| RSI += 256, RDI += 256  |
| DEC RCX, JNZ .loop      |
+-------------------------+
```

### Video: Character Output

```
+-------------------------+
| kernel_video_char(al)   |
+-------------------------+
            |
            v
+-------------------------+
| Disable cursor (nest)   |
| Acquire semaphore       |
+-------------------------+
            |
            v
    +------+------+
    | Char type?  |
    +------+------+
       |    |     |
  NEWLINE |  BACKSPACE  REGULAR
       |   |     |
       v   v     v
   Wrap  |  Move |  Clear cell
   line  |  back |  Render glyph
       |   |     |
       +---+-----+
            |
            v
+-------------------------+
| Advance cursor x        |
| Wrap to next line if    |
| past screen width       |
+-------------------------+
            |
            v
+-------------------------+
| Past bottom row?        |
+-------------------------+
            | YES
            v
+-------------------------+
| Scroll via              |
| kernel_memory_copy +    |
| kernel_video_line_drain |
+-------------------------+
            |
            v
+-------------------------+
| Store cursor position   |
| Release semaphore       |
| Enable cursor           |
+-------------------------+
```

### Video: Screen Scrolling

```
+-------------------------+
| kernel_video_scroll()   |
+-------------------------+
            |
            v
+-------------------------+
| kernel_memory_copy(     |
|   src = base + scanline |
|   dst = base,           |
|   len = scanline*(h-1)  |
| )                       |
+-------------------------+
            |
            v
+-------------------------+
| kernel_video_line_drain |
| (bottom row, background)|
+-------------------------+
```

### Interrupt Handling

```
+-------------------------+
| CPU Exception/Interrupt |
| (IDT Vector Fired)      |
+-------------------------+
            |
            v
+-------------------------+
| Push registers onto     |
| interrupt stack         |
+-------------------------+
            |
            v
    +-------------------+
    |  Interrupt Type?  |
    +-------------------+
        |       |       |
        v       v       v
    Exception   IRQ    Software
        |       |       |
        v       v       v
+----------+ +-----+ +--------+
| Exception| |Send | |Set CF  |
| Handler  | |EOI  | |Flag    |
| (panic)  | |to   | |in      |
|          | |APIC | |EFLAGS  |
+----------+ +-----+ +--------+
        |       |       |
        v       v       v
+-------------------------+
|     iretq               |
| Restore & Return        |
+-------------------------+
```

## Task Structure

```
+-----------------------------------+
|         KERNEL_STRUCTURE_TASK     |
+-----------------------------------+
|  cr3      (8 bytes) - Page Table  |
+-----------------------------------+
|  rsp      (8 bytes) - Stack Ptr   |
+-----------------------------------+
|  pid      (8 bytes) - Process ID  |
+-----------------------------------+
|  cpu      (8 bytes) - CPU Core    |
+-----------------------------------+
|  time     (8 bytes) - Creation    |
+-----------------------------------+
|  flags    (2 bytes) - Task Flags  |
+-----------------------------------+

Task Flags:
  bit 0: active     - Task is running
  bit 1: closed     - Task terminated
  bit 2: daemon     - Background task
  bit 3: processing - Currently executing
  bit 4: secured    - Task slot locked
  bit 5: thread     - Thread (no own page table)
```

## Key Systems

| System | Description |
|--------|-------------|
| **Video** | LFB framebuffer (32bpp, resolution read from multiboot, defaults 640x480), bitmap font rendering, cursor with nesting lock, SIMD-accelerated scrolling via `kernel_memory_copy` |
| **Paging** | 4-level page tables (PML4 → PDPT → PD → PT), 4 KB / 2 MB pages |
| **Memory** | Bitmap-based physical page allocator, SIMD-accelerated memory copy (`macro_copy`, 256 B/iter, prefetchnta + movdqa + movntdq) |
| **ACPI** | RSDP v1/v2 detection, RSDT (32-bit) and XSDT (64-bit) support, MADT parsing for LAPIC/IO-APIC enumeration |
| **Scheduling** | Round-robin scheduler driven by RTC at 1024 Hz, per-task flags (active, closed, daemon, processing, secured, thread) |
| **APIC** | Local APIC for timer interrupts, IO-APIC for device interrupt routing |
| **SMP** | Multi-processor boot via 16-bit real mode trampoline (`boot.asm`), AP wake through IPI, per-CPU GDT TSS entries |
| **Drivers** | PS/2 keyboard/mouse, RTC, PCI enumeration, IDE ATA/ATAPI, Intel 82540EM Gigabit Ethernet |
| **IPC** | Inter-process communication primitives |
| **Font** | Bitmap font glyph data loaded from `kernel/font/setfonts.asm`, font name displayed at boot |
| **Services** | Task reaper (tresher), network transmit (tx), network stack (IPv4/TCP/UDP/ICMP/ARP), HTTP server (port 80), interactive shell (clear, ip commands) |

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
