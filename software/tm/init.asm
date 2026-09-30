
 ; ask the stream owner to change the window title (if there is one)
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, tm_string_console_header_end - tm_string_console_header
 mov rsi, tm_string_console_header
 int KERNEL_SERVICE

 ; clear the character space
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, tm_string_init_end - tm_string_init
 mov rsi, tm_string_init
 int KERNEL_SERVICE

 ; display the fixed user interface elements
 call tm_static
