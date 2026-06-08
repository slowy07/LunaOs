 %include "luna/config.asm"

[BITS 16]

[ORG STATIC_LUNA_address]

luna:

 cli

 jmp 0x0000:.repair_cs

.repair_cs:
 xor ax, ax
 mov ds, ax
 mov es, ax
 mov ss, ax

 mov sp, STATIC_LUNA_stack

 cld

 mov al, STATIC_EMPTY
 out DRIVER_PIT_PORT_command, al

 sti


 mov ax, 0x2401
 int 0x15

 in al, 0x92
 or al, 2
 out 0x92, al

 mov ax, 0x0003
 int 0x10

 mov ah, 0x42
 mov si, luna_table_disk_address_packet
 int 0x13

 mov si, STATIC_LUNA_ERROR_device

 jc luna_panic

 xor ebx, ebx
 mov edx, 0x534D4150

 mov si, STATIC_LUNA_ERROR_memory

 mov edi, STATIC_LUNA_memory_map

.memory:
 mov eax, 0x14
 stosd

 mov eax, 0xE820
 mov ecx, 0x14
 int 0x15

 jc luna_panic

 add edi, 0x14

 test ebx, ebx
 jnz .memory

 mov al, 0xFF
 out DRIVER_PIC_PORT_SLAVE_data, al
 out DRIVER_PIC_PORT_MASTER_data, al

 cli

%if STATIC_LUNA_bit_mode = 16
 mov ax, STATIC_LUNA_kernel_address
 mov ds, ax
 mov es, ax

 sti

 mov ebx, STATIC_LUNA_memory_map

 jmp STATIC_LUNA_kernel_address:0x0000
%endif


 lgdt [luna_header_gdt_32bit]

 mov eax, cr0
 bts eax, 0
 mov cr0, eax

 jmp long 0x0008:luna_protected_mode

luna_panic:
 mov ax, 0xB800
 mov ds, ax

 mov word [ds:0x0000], si

 jmp $

[BITS 32]

luna_protected_mode:
 mov ax, 0x10
 mov ds, ax
 mov es, ax
 mov ss, ax


 mov ecx, edi
 sub ecx, STATIC_LUNA_memory_map

 mov edi, STATIC_LUNA_multiboot_header

 mov dword [edi + STATIC_MULTIBOOT_header.flags], STATIC_MULTIBOOT_HEADER_FLAG_memory_map

 mov dword [edi + STATIC_MULTIBOOT_header.mmap_length], ecx
 mov dword [edi + STATIC_MULTIBOOT_header.mmap_addr], STATIC_LUNA_memory_map

 mov esi, STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer
 mov edi, STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer
 mov ecx, (file_kernel_end - file_kernel) / 0x04
 rep movsd

%if STATIC_LUNA_bit_mode = 32
 mov ebx, STATIC_LUNA_multiboot_header

 jmp STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer
%endif


 xor eax, eax
 mov ecx, (STATIC_PAGE_SIZE_4KiB_byte * 0x06) / 0x04
 mov edi, STATIC_PML4_TABLE_address
 rep stosd

 mov dword [STATIC_PML4_TABLE_address], STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + STATIC_PAGE_FLAG_default

 mov dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte], STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x02) + STATIC_PAGE_FLAG_default
 mov dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x08], STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x03) + STATIC_PAGE_FLAG_default
 mov dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x10], STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x04) + STATIC_PAGE_FLAG_default
 mov dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x18], STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x05) + STATIC_PAGE_FLAG_default

 mov eax, STATIC_PAGE_FLAG_default + STATIC_PAGE_FLAG_2MiB_size
 mov ecx, 512 * 0x04
 mov edi, STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x02)

.next:
 stosd

 add edi, 0x04

 add eax, STATIC_PAGE_SIZE_2MiB_byte

 dec ecx
 jnz .next

 lgdt [luna_header_gdt_64bit]

 mov eax, 1010100000b
 mov cr4, eax

 mov eax, STATIC_PML4_TABLE_address
 mov cr3, eax

 mov ecx, 0xC0000080
 rdmsr
 or eax, 100000000b
 wrmsr

 mov eax, cr0
 or eax, 0x80000001
 mov cr0, eax

 jmp 0x0008:luna_long_mode

[BITS 64]

luna_long_mode:
 mov ebx, STATIC_LUNA_multiboot_header

 jmp STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer

 ret

align 0x04
luna_table_disk_address_packet:
 db 0x10
 db STATIC_EMPTY
 dw (file_kernel_end - file_kernel) / STATIC_SECTOR_SIZE_byte
 dw 0x0000
 dw STATIC_LUNA_kernel_address
 dq 0x0000000000000001

align 0x04
luna_table_gdt_32bit:
 dq STATIC_EMPTY
 dq 0000000011001111100110000000000000000000000000001111111111111111b
 dq 0000000011001111100100100000000000000000000000001111111111111111b
luna_table_gdt_32bit_end:

luna_header_gdt_32bit:
 dw luna_table_gdt_32bit_end - luna_table_gdt_32bit - 0x01
 dd luna_table_gdt_32bit

align 0x08
luna_table_gdt_64bit:
 dq STATIC_EMPTY
 dq 0000000000100000100110000000000000000000000000000000000000000000b
 dq 0000000000100000100100100000000000000000000000000000000000000000b
luna_table_gdt_64bit_end:

luna_header_gdt_64bit:
 dw luna_table_gdt_64bit_end - luna_table_gdt_64bit - 0x01
 dd luna_table_gdt_64bit

times 510 - ($ - $$) db STATIC_EMPTY
 dw STATIC_LUNA_magic

file_kernel:
 incbin "build/kernel"
 align STATIC_SECTOR_SIZE_byte
file_kernel_end:
