KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video equ 12

kernel_init_video:
 bt dword [ebx + HEADER_multiboot.flags], KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video
 jnc kernel_panic

 mov edi, dword [ebx + HEADER_multiboot.framebuffer_addr]
 mov qword [kernel_video_base_address], rdi
 mov qword [kernel_video_pointer], rdi

 mov eax, dword [ebx + HEADER_multiboot.framebuffer_width]
 mov dword [kernel_video_width_pixel], eax
 mov eax, dword [ebx + HEADER_multiboot.framebuffer_height]
 mov dword [kernel_video_height_pixel], eax

 call kernel_video_drain
