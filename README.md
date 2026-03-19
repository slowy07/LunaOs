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
- `ps2.txt` - PS/2 keyboard/mouse driver

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

## Key Systems

- **Paging**: 4-level page tables (PML4->PDPT->PD->PT), 4KB/2MB pages
- **Memory**: Bitmap-based page allocator
- **Tasking**: Round-robin scheduler with IRQ0 timer
- **APIC**: Local APIC for timer, IO-APIC for device interrupts
- **RTC**: 1024Hz periodic interrupts for task scheduling
- **PS/2**: Keyboard driver with scan code translation
