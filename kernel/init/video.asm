KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video equ 12

kernel_init_video:
 push rbx

 bt dword [ebx + HEADER_multiboot.flags], KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video
 jnc kernel_panic

 mov edi, dword [ebx + HEADER_multiboot.framebuffer_addr]
 mov qword [kernel_video_base_address], rdi
 mov qword [kernel_video_framebuffer], rdi
 mov qword [kernel_video_pointer], rdi

 mov eax, dword [ebx + HEADER_multiboot.framebuffer_height]
 mov dword [kernel_video_height_pixel], eax

 mov eax, dword [ebx + HEADER_multiboot.framebuffer_width]
 mov dword [kernel_video_width_pixel], eax

 shl rax, KERNEL_VIDEO_DEPTH_shift
 mul dword [kernel_font_height_pixel]
 mov qword [kernel_video_scanline_char], rax

 call kernel_video_drain

 mov ecx, kernel_init_string_welcome_end - kernel_init_string_welcome
 mov rsi, kernel_init_string_welcome
 call kernel_video_string

 mov ecx, kernel_init_string_video_end - kernel_init_string_video
 mov rsi, kernel_init_string_video
 call kernel_video_string

 mov rax, qword [kernel_video_width_pixel]
 mov ebx, STATIC_NUMBER_SYSTEM_decimal
 xor ecx, ecx
 call kernel_video_number

 mov ecx, kernel_init_string_video_separator_end - kernel_init_string_video_separator
 mov rsi, kernel_init_string_video_separator
 call kernel_video_string

 mov rax, qword [kernel_video_height_pixel]
 mov ebx, STATIC_NUMBER_SYSTEM_decimal
 xor ecx, ecx
 call kernel_video_number

 mov eax, STATIC_ASCII_NEW_LINE
 mov ecx, 1
 call kernel_video_char

 pop rbx
