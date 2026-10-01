
lulu_status:
 ; save the original registers
 push rax
 push rcx
 push rsi

 ; save the cursor position
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_cursor_save_end - lulu_string_cursor_save
 mov rsi, lulu_string_cursor_save
 int KERNEL_SERVICE

 ; set the cursor to the user communication position
 mov ecx, lulu_string_document_cursor_end - lulu_string_document_cursor
 mov rsi, lulu_string_document_cursor
 mov word [lulu_string_document_cursor.x], r8w
 sub word [lulu_string_document_cursor.x], lulu_string_document_cursor_end - lulu_string_document_cursor
 mov word [lulu_string_document_cursor.y], r9w
 inc word [lulu_string_document_cursor.y]
 int KERNEL_SERVICE

 ; has the document been modified since the last write/read?
 cmp byte [lulu_modified_semaphore], STATIC_FALSE
 je .no_modified ; no

 ; display the information about the modified document
 mov ecx, lulu_string_modified_end - lulu_string_modified
 mov rsi, lulu_string_modified
 int KERNEL_SERVICE

 ; the document status has been displayed
 mov byte [lulu_modified_semaphore], STATIC_FALSE

.no_modified:
 ; restore the cursor position
 mov ecx, lulu_string_cursor_restore_end - lulu_string_cursor_restore
 mov rsi, lulu_string_cursor_restore
 int KERNEL_SERVICE

 ; restore the original registers
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret
