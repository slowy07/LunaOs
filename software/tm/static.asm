
tm_static:
 ; fetch the output stream information
 call tm_stream_info

 ; display the system uptime
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, tm_string_uptime_end - tm_string_uptime
 mov rsi, tm_string_uptime
 int KERNEL_SERVICE

 ; display the number of processes
 mov ecx, tm_string_tasks_end - tm_string_tasks
 mov rsi, tm_string_tasks
 int KERNEL_SERVICE

 ; display the RAM usage
 mov ecx, tm_string_memory_end - tm_string_memory
 mov rsi, tm_string_memory
 int KERNEL_SERVICE

 ; display the process table header
 mov ecx, tm_string_header_end - tm_string_header_position
 mov rsi, tm_string_header_position
 int KERNEL_SERVICE
 mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
 movzx ecx, word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
 sub ecx, tm_string_header_end - tm_string_header
 mov dl, STATIC_SCANCODE_SPACE
 int KERNEL_SERVICE

 ; display the program menu
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, tm_string_menu_end - tm_string_menu
 mov rsi, tm_string_menu
 int KERNEL_SERVICE

 ; return from the procedure
 ret

 macro_debug "software: tm_static"
