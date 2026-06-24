%include "luna/config.asm"

[BITS 16]

[ORG STATIC_LUNA_base_address]

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

mov ax, 0x0003
int 0x10

mov ah, 0x42
mov si, luna_table_disk_address_packet
int 0x13

mov si, STATIC_LUNA_ERROR_disk

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

mov ax, 0x4F00
mov si, STATIC_LUNA_ERROR_video
mov di, STATIC_LUNA_video_vga_info_block
int 0x10

test ax, 0x4F00
jnz luna_panic

mov esi, dword [di + STATIC_LUNA_VIDEO_STRUCTURE_VGA_INFO_BLOCK.video_mode_ptr]

.loop:

cmp word [esi], 0xFFFF
je .error

mov ax, 0x4F01
mov cx, word [esi]
mov di, STATIC_LUNA_video_mode_info_block
int 0x10

cmp word [di + STATIC_LUNA_VIDEO_STRUCTURE_MODE_INFO_BLOCK.x_resolution], MULTIBOOT_VIDEO_WIDTH_pixel
jne .next

cmp word [di + STATIC_LUNA_VIDEO_STRUCTURE_MODE_INFO_BLOCK.y_resolution], MULTIBOOT_VIDEO_HEIGHT_pixel
jne .next

cmp byte [di + STATIC_LUNA_VIDEO_STRUCTURE_MODE_INFO_BLOCK.bits_per_pixel], STATIC_LUNA_VIDEO_DEPTH_bit
je .found

.next:

add esi, STATIC_WORD_SIZE_byte

jmp .loop

.error:

mov si, STATIC_LUNA_ERROR_video
jmp luna_panic

.found:

mov ax, 0x4F02
mov bx, word [esi]
or bx, STATIC_LUNA_VIDEO_MODE_linear | STATIC_LUNA_VIDEO_MODE_clean
int 0x10

test ah, ah
jnz .error

cli

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

luna_line_a20_check:

push ds

mov ax, 0xFFFF
mov ds, ax

mov ebx, dword [ds:STATIC_LUNA_base_address + 0x10]

pop ds

test ebx, dword [ds:STATIC_LUNA_base_address]

ret

luna_ps2_keyboard_in:

in al, 0x64
test al, 2

jnz luna_ps2_keyboard_in

ret

luna_ps2_keyboard_out:

in al, 0x64
test al, 1

jz luna_ps2_keyboard_out

ret

[BITS 32]

luna_protected_mode:

mov ax, 0x10
mov ds, ax
mov es, ax
mov ss, ax

mov ecx, edi
sub ecx, STATIC_LUNA_memory_map

mov edi, STATIC_LUNA_multiboot_header

mov dword [edi + STATIC_MULTIBOOT_header.flags], STATIC_MULTIBOOT_HEADER_FLAG_memory_map | STATIC_MULTIBOOT_HEADER_FLAG_video

mov dword [edi + STATIC_MULTIBOOT_header.mmap_length], ecx
mov dword [edi + STATIC_MULTIBOOT_header.mmap_addr], STATIC_LUNA_memory_map

mov eax, dword [STATIC_LUNA_video_mode_info_block + STATIC_LUNA_VIDEO_STRUCTURE_MODE_INFO_BLOCK.physical_base_address]
mov dword [edi + STATIC_MULTIBOOT_header.framebuffer_addr], eax
mov dword [edi + STATIC_MULTIBOOT_header.framebuffer_width], MULTIBOOT_VIDEO_WIDTH_pixel
mov dword [edi + STATIC_MULTIBOOT_header.framebuffer_height], MULTIBOOT_VIDEO_HEIGHT_pixel
mov byte [edi + STATIC_MULTIBOOT_header.framebuffer_bpp], STATIC_LUNA_VIDEO_DEPTH_bit
mov byte [edi + STATIC_MULTIBOOT_header.framebuffer_type], STATIC_EMPTY

mov esi, STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer
mov edi, STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer
mov ecx, (file_kernel_end - file_kernel) / 0x04
rep movsd

mov ebx, STATIC_LUNA_multiboot_header

jmp STATIC_LUNA_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer

align 0x04
luna_table_disk_address_packet:
db 0x10
db STATIC_EMPTY
dw (file_kernel_end - file_kernel) / STATIC_SECTOR_SIZE_byte
dw 0x0000
dw STATIC_LUNA_kernel_address
dq 0x0000000000000001

align 0x10
luna_table_gdt_32bit:

dq STATIC_EMPTY

dq 0000000011001111100110000000000000000000000000001111111111111111b

dq 0000000011001111100100100000000000000000000000001111111111111111b
luna_table_gdt_32bit_end:

luna_header_gdt_32bit:
dw luna_table_gdt_32bit_end - luna_table_gdt_32bit - 0x01
dd luna_table_gdt_32bit

times 436 - ( $ - $$ ) db 0x00

db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

db 0x00
db 0x00, 0x00, 0x00
db 0xEB
db 0x00, 0x00, 0x00
dd (file_kernel_end - $$) / 512
dd (1048576 - (file_kernel_end - $$)) / 512

times 510 - ($ - $$) db STATIC_EMPTY
dw STATIC_LUNA_magic

file_kernel:

incbin "build/kernel"
align STATIC_SECTOR_SIZE_byte
file_kernel_end:

times 1048576 - ($ - $$) db STATIC_EMPTY

