
 ; ask the stream owner to change the window title (if there is one)
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_console_header_end - lulu_string_console_header
 mov rsi, lulu_string_console_header
 int KERNEL_SERVICE

 ; display the user interface
 call lulu_interface

 ; fetch the size of the argument list passed to the process
 pop rcx

 ; were the arguments passed to the process?
 test rcx, rcx
 jz .no_arguments ; no

 ; point the pointer at the argument list
 mov rsi, rsp

 ; remove the white characters from the beginning and the end of the string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

.no_arguments:
 ; prepare the space properties for the document
 call lulu_document_area

 ; buffer size: terminal width - number of characters in lulu_string_menu_read - 0x01
 mov rax, r8
 sub rax, lulu_string_menu_read_end - lulu_string_menu_read
 dec rax

 ; save the information about the buffer
 sub rsp, rax
 mov qword [lulu_cache_size_byte], rax
 mov qword [lulu_cache_address], rsp
