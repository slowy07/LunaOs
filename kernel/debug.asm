kernel_debug_string_welcome db STATIC_COLOR_ASCII_MAGENTA_LIGHT, "ESC to enter debug mode", STATIC_ASCII_NEW_LINE
kernel_debug_string_welcome_end:

kernel_debug:
 push rax
 push rbx
 push rcx
 push rdx
 push rdi
 push rsi
 push rbp
 push r8
 push r9
 push r10
 push r11
 push r12
 push r13
 push r14
 push r15

 sti

 mov ecx, kernel_debug_string_welcome_end - kernel_debug_string_welcome
 mov rsi, kernel_debug_string_welcome
 call kernel_video_string

.any:
 call driver_ps2_keyboard_read
 jz .any

 cmp ax, STATIC_ASCII_ESCAPE
 jne .any

 call kernel_video_drain
 
 jmp $

 macro_debug "kernel_debug"
