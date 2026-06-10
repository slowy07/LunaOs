HEADER_MAGIC equ 0x1BADB002

HEADER_FLAG_align equ 1 << 0
HEADER_FLAG_memory_map equ 1 << 1
HEADER_FLAG_video equ 1 << 2
HEADER_FLAG_header equ 1 << 16
HEADER_FLAG_default equ HEADER_FLAG_align | HEADER_FLAG_memory_map | HEADER_FLAG_video | HEADER_FLAG_header

HEADER_CHECKSUM equ -(HEADER_FLAG_default + HEADER_MAGIC)

struc HEADER_multiboot
 .flags resb 4
 .unsupported0 resb 40
 .mmap_length resb 4
 .mmap_addr resb 4
 .unsupported1 resb 36
 .framebuffer_addr resb 8
 .framebuffer_pitch resb 4
 .framebuffer_width resb 4
 .framebuffer_height resb 4
 .framebuffer_bpp resb 1
 .framebuffer_type resb 1
 .color_info resb 6
endstruc

align 0x04
header:
 dd HEADER_MAGIC
 dd HEADER_FLAG_default
 dd HEADER_CHECKSUM
 dd header
 dd init
 dd STATIC_EMPTY
 dd STATIC_EMPTY
 dd init
 dd STATIC_EMPTY
 dd KERNEL_VIDEO_WIDTH_pixel
 dd KERNEL_VIDEO_HEIGHT_pixel
 dd KERNEL_VIDEO_DEPTH_bit

align 0x10
header_end:
