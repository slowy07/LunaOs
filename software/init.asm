 %include "config.asm"
 %include "kernel/config.asm"

[BITS 64]

[DEFAULT REL]

[ORG SOFTWARE_base_address]

init:

 mov ax, KERNEL_SERVICE_VIDEO_string
 mov ecx, kernel_init_string_end - kernel_init_string
 mov rsi, kernel_init_string
 int KERNEL_SERVICE

 mov ax, KERNEL_SERVICE_PROCESS_run
 mov ecx, init_program_shell_end - init_program_shell
 xor edx, edx
 mov rsi, init_program_shell
 int KERNEL_SERVICE

 jmp $

 mov ax, KERNEL_SERVICE_PROCESS_pid

.wait_for_shell:

 int KERNEL_SERVICE
 jnc .wait_for_shell

 jmp init

 %include "software/init/data.asm"

