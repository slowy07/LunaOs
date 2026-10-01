
; exit:
;	CF flag - if error
;	rcx - number of characters in the file name
;	rsi - pointer to the string holding the file name/path
lulu_shortcut_file:
 ; save the original registers
 push rax
 push rbx
 push rdx
 push rdi
 push rsi
 push rcx

 ; release the CTRL key
 mov byte [lulu_key_ctrl_semaphore], STATIC_FALSE

 ; save the cursor position
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_cursor_save_end - lulu_string_cursor_save
 mov rsi, lulu_string_cursor_save
 int KERNEL_SERVICE

 ; set the cursor to the user communication position
 mov ecx, lulu_string_document_cursor_end - lulu_string_document_cursor
 mov rsi, lulu_string_document_cursor
 mov word [lulu_string_document_cursor.x], STATIC_EMPTY
 mov word [lulu_string_document_cursor.y], r9w
 inc word [lulu_string_document_cursor.y]
 int KERNEL_SERVICE

 ; display the file name query
 mov ecx, lulu_string_menu_read_end - lulu_string_menu_read
 mov rsi, lulu_string_menu_read
 int KERNEL_SERVICE

 ; fetch the file name(path)
 mov rbx, qword [lulu_cache_size_byte] ; buffer size
 xor ecx, ecx ; the buffer is empty
 mov rdx, lulu_ipc ; exception handling
 mov rsi, qword [lulu_cache_address]
 mov rdi, lulu_ipc_data
 macro_library LIBRARY_STRUCTURE_ENTRY.input

 ; save the original registers and the state of the CF flag
 pushf
 push rcx
 push rsi

 ; remove the file name query
 mov ecx, lulu_string_line_clean_end - lulu_string_line_clean
 mov rsi, lulu_string_line_clean
 int KERNEL_SERVICE

 ; restore the original registers and the state of the CF flag
 pop rsi
 pop rcx
 popf

 ; no file name/path fetched?
 jc .end ; yes

 ; remove the "white characters" from the string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .end ; empty string

 ; return the information about the string
 mov qword [rsp], rcx
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rsi

.end:
 ; restore the original registers
 pop rcx
 pop rsi
 pop rdi
 pop rdx
 pop rbx
 pop rax

 ; return from the procedure
 ret

; entry:
;	ax - key code
lulu_shortcut:
 ; is the CTRL key held down?
 cmp byte [lulu_key_ctrl_semaphore], STATIC_FALSE
 je .no_key ; no

 ; was the "x" key pressed?
 cmp ax, "x"
 je lulu.end ; yes

 ; was the "r" key pressed?
 cmp ax, "r"
 je .read_file ; yes

 ; was the "o" key pressed?
 cmp ax, "o"
 je .write_file ; yes

 ; unrecognized keyboard shortcut
 jmp .no_key

.restore_cursor:
 ; restore the cursor position
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_cursor_restore_end - lulu_string_cursor_restore
 mov rsi, lulu_string_cursor_restore
 int KERNEL_SERVICE

.no_key:
 ; unrecognized keyboard shortcut
 stc

.end:
 ; return from the procedure
 ret

.write_file:
 ; fetch the file name from the user
 call lulu_shortcut_file
 jc lulu_shortcut.restore_cursor ; no file name given

 ; save the file properties
 push rcx
 push rsi
 push STATIC_FALSE ; local variable

 ; check whether a file of the given name already exists
 mov ax, KERNEL_SERVICE_VFS_exist
 int KERNEL_SERVICE
 jc .write_file_ready ; does not exist

 ; ask whether to overwrite the file
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_menu_overwrite_end - lulu_string_menu_overwrite
 mov rsi, lulu_string_menu_overwrite
 int KERNEL_SERVICE

.write_file_wait:
 ; fetch the "character from the keyboard buffer" message
 mov ax, KERNEL_SERVICE_PROCESS_ipc_receive
 mov rdi, lulu_ipc_data
 int KERNEL_SERVICE
 jc .write_file_wait ; no message

 ; message of the keyboard type?
 cmp byte [rdi + KERNEL_IPC_STRUCTURE.type], KERNEL_IPC_TYPE_KEYBOARD
 jne .write_file_wait ; yes

 ; "Enter" key?
 cmp word [rdi + KERNEL_IPC_STRUCTURE.data], STATIC_SCANCODE_RETURN
 je .write_file_answer ; yes

 ; "Esc" key?
 cmp word [rdi + KERNEL_IPC_STRUCTURE.data], STATIC_SCANCODE_ESCAPE
 jne .write_file_wait ; no, keep waiting

.write_file_answer:
 ; remove the file overwrite query
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_menu_answer_end - lulu_string_menu_answer
 mov rsi, lulu_string_menu_answer
 int KERNEL_SERVICE

.write_file_ready:
 ; restore the file properties
 add rsp, STATIC_QWORD_SIZE_byte ; free the local variable
 pop rsi
 pop rcx

 ; negative answer?
 cmp word [rdi + KERNEL_IPC_STRUCTURE.data], STATIC_SCANCODE_ESCAPE
 je lulu_shortcut.restore_cursor

 ; store the document contents in a file of the given name
 mov ax, KERNEL_SERVICE_VFS_write
 mov rdx, qword [lulu_document_size]
 mov rdi, qword [lulu_document_start_address]
 int KERNEL_SERVICE
 jnc lulu_shortcut.restore_cursor

 ; display the error message
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_menu_failed_write_end - lulu_string_menu_failed_write
 mov rsi, lulu_string_menu_failed_write
 int KERNEL_SERVICE

 ; end of the keyboard shortcut handling
 jmp lulu_shortcut.restore_cursor

 macro_debug "lulu_shortcut.save_file"

.read_file:
 ; fetch the file name from the user
 call lulu_shortcut_file
 jc lulu_shortcut.restore_cursor ; no file name given

 ; process the document/file
 call lulu_document_format
 jnc lulu_shortcut.end

 ; display the information about the missing file to read
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_menu_not_found_end - lulu_string_menu_not_found
 mov rsi, lulu_string_menu_not_found
 int KERNEL_SERVICE

 ; end of the keyboard shortcut handling
 jmp lulu_shortcut.restore_cursor

 macro_debug "lulu_shortcut.read_file"
