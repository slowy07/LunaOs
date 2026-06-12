 %include "kernel/service/shell/config.asm"

service_shell:
 mov ecx, service_shell_string_prompt_end - service_shell_string_prompt_with_new_line
 mov rsi, service_shell_string_prompt_with_new_line

 cmp dword [kernel_video_cursor.x], STATIC_EMPTY
 jne .prompt

 mov ecx, service_shell_string_prompt_end - service_shell_string_prompt
 mov rsi, service_shell_string_prompt

.prompt:
 call kernel_video_string

.restart:
 xor ebx, ebx

 mov ecx, SERVICE_SHELL_CACHE_SIZE_byte

 mov rsi, service_shell_cache

 call library_input
 jc service_shell

 call library_string_trim
 jc service_shell

 call library_string_word_next

 jmp service_shell_prompt

 %include "kernel/service/shell/data.asm"
 %include "kernel/service/shell/prompt.asm"
