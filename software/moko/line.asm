
moko_line_clear_last:
 ; save the original registers
 push rax
 push rcx
 push rsi

 ; set the cursor to the last line of the document
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, moko_string_document_cursor_end - moko_string_document_cursor
 mov rsi, moko_string_document_cursor
 mov word [moko_string_document_cursor.x], STATIC_EMPTY
 mov word [moko_string_document_cursor.y], r9w
 int KERNEL_SERVICE

 ; clear
 mov ecx, moko_string_line_clean_end - moko_string_line_clean
 mov rsi, moko_string_line_clean
 int KERNEL_SERVICE

 ; restore the original registers
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

; entry:
;	rcx - line number to check
; exit:
;	CF flag if error
;	rcx - size of the document line
;	rsi - pointer to the beginning of the line
moko_line_this:
 ; save the original registers
 push rax
 push rcx
 push rsi

 ; set the pointer to the beginning of the document space
 mov rsi, qword [moko_document_start_address]

 ; fetch the information about the first line of the document?
 test rcx, rcx
 jz .first_line ; yes

.search:
 ; end of the document?
 cmp rsi, qword [moko_document_end_address]
 je .error ; the given line was not found in the document

 ; fetch the first character of the line
 lodsb

 ; newline character
 cmp al, STATIC_SCANCODE_NEW_LINE
 jne .search ; no

 ; end of line recognized, look for the next one?
 dec rcx
 jnz .search ; yes

.first_line:
 ; save the pointer to the beginning of the line in the document
 push rsi

.length:
 ; end of the document?
 cmp rsi, qword [moko_document_end_address]
 je .ready ; the line size has been determined

 ; look for the end of line character
 lodsb

 ; end?
 cmp al, STATIC_SCANCODE_NEW_LINE
 je .ready ; yes

 ; number of characters in the line
 inc rcx
 jmp .length ; continue

.ready:
 ; restore the pointer to the beginning of the given line
 pop rsi

 ; return the information about the beginning of the given line and its size
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx
 mov qword [rsp], rsi

 ; end of the procedure
 jmp .end

.error:
 ; flag, error
 stc

.end:
 ; restore the original registers
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

; entry:
;	rbx - row number on the screen
;	rcx - number of the document line to display
moko_line_number:
 ; save the original registers
 push rax
 push rcx
 push rsi
 push r10
 push r11
 push r12
 push r13
 push r15

 ; fetch the information about the given line
 call moko_line_this
 jc .end ; no information about the given line

 ; set the properties of the previous line
 mov r10, rsi ; pointer to the beginning of the line in the document
 xor r11, r11 ; inner line pointer at the beginning
 xor r12, r12 ; display the whole line from the beginning
 mov r13, rcx ; size of the line
 mov r15, rbx ; in the line provided for it

 ; display
 call moko_line

.end:
 ; restore the original registers
 pop r15
 pop r13
 pop r12
 pop r11
 pop r10
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

; entry:
;	rcx - size of the examined line
;	rsi - pointer to the beginning of the examined line
moko_line_update:
 ; pointer to the cursor position in the document space
 mov r10, rsi

 ; size of the newline
 mov r13, rcx

 ; is the last used column number within the size range of the current line?
 cmp qword [moko_document_line_index_last], r13
 jbe .in_line ; yes

 ; set the inner document pointer to the end of the line
 add r10, rcx

 ; set the inner line offset to the end of the line
 mov r11, rcx

 ; display the line from its first character
 xor r12, r12

 ; set the cursor in the column matching the end of line position
 mov r14, rcx

 ; end of the procedure
 ret

.in_line:
 ; display the line based on the last known properties
 mov r11, qword [moko_document_line_index_last]
 mov r12, qword [moko_document_line_begin_last]

 ; set the inner document pointer to the position
 add r10, r11

 ; set the cursor in the matching column
 mov r14, r11

 ; does the whole line fit in the screen space?
 cmp rcx, r8
 jbe .end ; yes

 ; set the cursor in the matching column
 mov r14, r11
 sub r14, r12

.end:
 ; end of the procedure
 ret

; exit:
;	CF flag, if the beginning of the document
;	rcx - size of the previous line
;	rsi - pointer to the beginning of the previous line in the document
moko_line_previous:
 ; save the original registers
 push rsi

 ; set the pointer before the newline character, based on the current line
 mov rsi, r10
 sub rsi, r11

 ; beginning of the document?
 cmp rsi, qword [moko_document_start_address]
 ja .ok ; no

 ; flag, error
 stc

 ; end
 jmp .end

.ok:
 ; start before the newline character
 dec rsi

 ; determine the position and the size of the previous line
 xor ecx, ecx ; size

.loop:
 ; beginning of the document?
 cmp rsi, qword [moko_document_start_address]
 je .found ; yes

 ; end of the previous line?
 cmp byte [rsi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_NEW_LINE
 je .found ; yes

 ; number of characters + 1
 inc rcx

 ; next (previous) character in the line
 dec rsi

 ; end of the document?
 cmp rsi, qword [moko_document_start_address]
 jne .loop ; no

.found:
 ; return the information about the start position of the previous line in the document
 mov qword [rsp], rsi

.end:
 ; restore the original registers
 pop rsi

 ; return from the procedure
 ret

; exit:
;	CF flag - if end of the document
;	rcx - line size in characters
;	rsi - pointer to the beginning of the next line
moko_line_next:
 ; save the original registers
 push rsi

 ; set the pointer before the newline character, based on the current line
 mov rsi, r10
 sub rsi, r11
 add rsi, r13

 ; end of the document?
 cmp rsi, qword [moko_document_end_address]
 jb .ok ; no

 ; flag, error
 stc

 ; end
 jmp .end

.ok:
 ; start after the newline character
 inc rsi

 ; determine the position and the size of the previous line
 xor ecx, ecx ; size

.loop:
 ; end of the document?
 cmp rsi, qword [moko_document_end_address]
 je .found ; yes

 ; end of the next line?
 cmp byte [rsi], STATIC_SCANCODE_NEW_LINE
 je .found ; yes

 ; number of characters + 1
 inc rcx

 ; next character in the line
 inc rsi

 ; continue
 jmp .loop

.found:
 ; set the pointer to the beginning of the line
 sub rsi, rcx

 ; return the information about the start position of the next line in the document
 mov qword [rsp], rsi

.end:
 ; restore the original registers
 pop rsi

 ; return from the procedure
 ret

moko_line:
 ; save the original registers
 push rax
 push rcx
 push rdx
 push rsi

 ; set the cursor to the beginning of the current row of the character space
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, moko_string_document_cursor_end - moko_string_document_cursor
 mov rsi, moko_string_document_cursor
 mov word [moko_string_document_cursor.x], STATIC_EMPTY
 mov word [moko_string_document_cursor.y], r15w
 int KERNEL_SERVICE

 ; set the pointer to the beginning/fragment of the line to display
 mov rsi, r10
 sub rsi, r11
 add rsi, r12

 ; number of characters of the line to display
 mov rcx, r13
 sub rcx, r12
 cmp rcx, r8
 jb .visible ; number of characters smaller than the screen width

 ; display the maximum number of characters on the screen
 mov rcx, r8
 dec rcx ; the last column is always empty

.visible:
 ; is the line empty?
 test rcx, rcx
 jz .empty ; yes

 ; display a string of the given length in sequence
 int KERNEL_SERVICE

.empty:
 ; clear the rest of the line?
 cmp r8, rcx
 je .no ; no

 ; the remaining part of the line with a space character
 mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
 sub rcx, r8
 not rcx ; convert into an absolute value
 mov dl, STATIC_SCANCODE_SPACE
 int KERNEL_SERVICE

.no:
 ; set the cursor to the position
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, moko_string_document_cursor_end - moko_string_document_cursor
 mov rsi, moko_string_document_cursor
 mov word [moko_string_document_cursor.x], r14w
 mov word [moko_string_document_cursor.y], r15w
 int KERNEL_SERVICE

 ; restore the original registers
 pop rsi
 pop rdx
 pop rcx
 pop rax

 ; return from the procedure
 ret
