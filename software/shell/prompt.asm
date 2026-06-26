shell_prompt_clean:

 add rsi, rbx
 sub r8, rbx

 mov rcx, r8
 call library_string_trim

 mov r8, rcx

.error:

 ret

shell_prompt:

 mov r8, rcx

 cmp rbx, shell_command_clean_end - shell_command_clean
 jne .no_clean

 mov ecx, ebx
 mov rdi, shell_command_clean
 call library_string_compare
 jc .no_clean

 mov ax, KERNEL_SERVICE_VIDEO_clean
 int KERNEL_SERVICE

 jmp .end

.no_clean:
 cmp rbx, shell_command_exit_end - shell_command_exit
 jne .no_exit

 mov ecx, ebx
 mov rdi, shell_command_exit
 call library_string_compare
 jc .no_exit

 xor ax, ax
 int KERNEL_SERVICE

.no_exit:
 nop

.end:

 jmp shell

