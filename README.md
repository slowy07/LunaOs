# LunaOs
Multitasking operating system written in assembly x86_64 (formerly aidenOS)

## Requirements

- nasm
- qemu

## Running

```
nasm -f bin kernel/kernel.asm -o build/kernel
nasm -f bin luna/luna.asm -o build/luna.raw
```

**Playing with qemu**
```
qemu-system-x86_64 -drive file=build/luna.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime
```

## Documentation

Documentation is organized in the following structure:

### Root Documentation
- `docs/config.txt` - Global configuration constants

### Kernel Documentation (`kernel/docs/`)
- `config.txt` - Kernel configuration
- `idt.txt` - Interrupt Descriptor Table management
- `data.txt` - Data structures (GDT, TSS, IDT headers)
- `page.txt` - Page management and virtual memory
- `memory.txt` - Memory allocation system
- `video.txt` - VGA video output
- `panic.txt` - Panic handler
- `io_apic.txt` - IO-APIC support
- `kernel.txt` - Main kernel module
- `init.txt` - Initialization chain
- `macro_close.txt` - Semaphore lock macro
- `macro_apic.txt` - APIC ID macro

### Kernel Init Documentation (`kernel/init/docs/`)
- `task.txt` - Task initialization
- `rtc.txt` - RTC initialization
- `idt.txt` - IDT initialization
- `page.txt` - Page initialization
- `panic.txt` - Panic handler initialization
- `gdt.txt` - GDT initialization
- `data.txt` - Data/strings initialization
- `video.txt` - Video initialization
- `multiboot.txt` - Multiboot header
- `memory.txt` - Memory initialization
- `long_mode.txt` - Long mode (64-bit) transition
- `acpi.txt` - ACPI initialization

### Driver Documentation (`kernel/driver/`)
- `driver_docs.txt` - RTC driver documentation
- `ps2.txt` - PS/2 keyboard/mouse driver (includes interrupt flow diagram, scan code tables, and I/O port specifications)

### Library Documentation (`library/docs/`)
- `page_align_up.txt` - Page alignment utility
- `page_from_size.txt` - Size to page conversion

## Architecture Overview

```
bootloader (GRUB/QEMU)
        |
        v
kernel/kernel.asm
        |
        +---> kernel/init.asm (32-bit -> 64-bit transition)
        |         |
        |         +-- video.asm
        |         +-- memory.asm
        |         +-- acpi.asm
        |         +-- page.asm
        |         +-- gdt.asm
        |         +-- idt.asm
        |         +-- rtc.asm
        |         +-- task.asm
        |
        +---> kernel/panic.asm
        +---> kernel/page.asm
        +---> kernel/memory.asm
        +---> kernel/video.asm
        +---> kernel/apic.asm
        +---> kernel/io_apic.asm
        +---> kernel/idt.asm
        +---> kernel/task.asm
        +---> kernel/driver/rtc.asm
        +---> kernel/driver/ps2.asm
```

## Process Flow Diagrams

### Boot Process Flow

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
```

### Kernel Initialization Sequence

```
+-------------------------+
|   kernel_init_long_mode |
+-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   video.asm             | --> |   Display Init          |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   memory.asm            | --> |   Physical Memory Map   |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   acpi.asm              | --> |   ACPI Table Parsing    |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   page.asm              | --> |   Virtual Memory Setup  |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   gdt.asm               | --> |   Segment Descriptors   |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   idt.asm               | --> |   Interrupt Vectors     |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   rtc.asm               | --> |   Timer Setup (1024Hz)  |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   ps2.asm               | --> |   Keyboard/Mouse Init   |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+     +-------------------------+
|   task.asm              | --> |   Scheduler Init        |
+-------------------------+     +-------------------------+
            |
            v
+-------------------------+
|   kernel_init_apic      |
|   Enable Timer          |
+-------------------------+
```

### Task Scheduler Flow (Round-Robin)

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
| (RSP,CR3,FXR) |  | Block in Queue  |
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

### Memory Management Flow

```
+-------------------------+
| kernel_memory_alloc()   |
+-------------------------+
            |
            v
+-------------------------+
| Search Bitmap for       |
| Free Pages (bt qword)   |
+-------------------------+
            |
            v
+-------------------------+
| Find Contiguous Block   |
| of Required Size        |
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
| Lock Pages     |  | Return Error    |
| (btr bitmap)   |  | (stc flag)      |
+----------------+  +-----------------+
        |
        v
+-------------------------+
| Return Physical Address |
| (page_index << 12 +     |
|  KERNEL_BASE_address)   |
+-------------------------+
```

### Virtual Memory (Paging) Flow

```
+-------------------------+
| kernel_page_map_logical |
|   or _map_physical      |
+-------------------------+
            |
            v
+-------------------------+
| kernel_page_prepare()   |
| Calculate PML4/PML3/    |
| PML2/PML1 indices       |
+-------------------------+
            |
            v
    +-------------------+
    |  PML4 Entry       |
    |  Exists?          |
    +-------------------+
        |           |
       Yes          No
        |           |
        v           v
+----------------+  +-----------------+
| Use Existing   |  | Alloc & Init    |
| PML4 Entry     |  | New PML3 Page   |
+----------------+  +-----------------+
        |
        v
    +-------------------+
    |  PML3 Entry       |
    |  Exists?          |
    +-------------------+
        |           |
       Yes          No
        |           |
        v           v
+----------------+  +-----------------+
| Use Existing   |  | Alloc & Init    |
| PML3 Entry     |  | New PML2 Page   |
+----------------+  +-----------------+
        |
        v
    +-------------------+
    |  PML2 Entry       |
    |  Exists?          |
    +-------------------+
        |           |
       Yes          No
        |           |
        v           v
+----------------+  +-----------------+
| Use Existing   |  | Alloc & Init    |
| PML2 Entry     |  | New PML1 Page   |
+----------------+  +-----------------+
        |
        v
+-------------------------+
| Fill PML1 Entry with    |
| Physical Page Address   |
+-------------------------+
```

### Interrupt Handling Flow

```
+-------------------------+
| CPU Exception/Interrupt |
| (IDT Vector Fired)      |
+-------------------------+
            |
            v
+-------------------------+
| Push Registers onto     |
| Interrupt Stack         |
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

### Task Structure Layout

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

- **Paging**: 4-level page tables (PML4->PDPT->PD->PT), 4KB/2MB pages
- **Memory**: Bitmap-based page allocator
- **Tasking**: Round-robin scheduler with IRQ0 timer
- **APIC**: Local APIC for timer, IO-APIC for device interrupts
- **RTC**: 1024Hz periodic interrupts for task scheduling
- **PS/2**: Keyboard driver with scan code translation
