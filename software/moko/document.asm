;===============================================================================

;===============================================================================
; entry:
;	rcx - size of the document in bytes
;	rdi - pointer to the beginning of the document
moko_document_analyze:
	; reset the local and global variables to their default values
	mov	qword [moko_document_show_from_line],	STATIC_EMPTY
	mov	qword [moko_document_line_begin_last],	STATIC_EMPTY
	mov	qword [moko_document_line_index_last],	STATIC_EMPTY
	mov	qword [moko_document_line_count],	STATIC_EMPTY
	mov	r10,	qword [moko_document_start_address]
	xor	r11,	r11
	xor	r12,	r12
	xor	r14,	r14
	xor	r15,	r15

	; remove the "caret" characters from the document, Moko does not handle them by default
	mov	rsi,	rdi
	call	moko_document_enter_remove

	; set the size of the document in bytes
	mov	qword [moko_document_size],	rcx

	; save the pointer to the end of the document
	add	rdi,	rcx
	mov	qword [moko_document_end_address],	rdi

	; fetch the information about the first line of the document
	xor	ecx,	ecx
	call	moko_line_this
	jc	.end	; empty document

	; size of the current line in characters
	mov	r13,	rcx

	; move the pointer past the first line of the document
	add	rsi,	r13
	mov	rcx,	qword [moko_document_size]
	sub	rcx,	r13

.loop:
	; end of the document?
	cmp	rsi,	rdi
	je	.end	; yes

	; count the number of lines in the document
	cmp	byte [rsi],	STATIC_SCANCODE_NEW_LINE
	jne	.next	; next

	; end of line found
	inc	qword [moko_document_line_count]

.next:
	; next character from the document
	inc	rsi

	; all found?
	dec	rcx
	jnz	.loop	; no

.end:
	; return from the procedure
	ret

;===============================================================================
; entry:
;	rcx - size of the document in bytes
;	rsi - pointer to the beginning of the document
moko_document_enter_remove:
	; save the original registers
	push	rsi
	push	rdi
	push	rcx

.loop:
	; "caret" character?
	cmp	byte [rsi],	STATIC_SCANCODE_RETURN
	jne	.next	; no

	; save the pointer and the size of the remaining document to process
	push	rcx
	push	rsi

	; remove the "caret" character from the document
	mov	rdi,	rsi
	inc	rsi
	rep	movsb

	; restore the pointer and the size of the remaining document to process
	pop	rsi
	pop	rcx

	; the document size has decreased
	dec	qword [rsp]

	; continue
	jmp	.return

.next:
	; move the pointer to the next character
	inc	rsi

.return:
	; has the document been processed?
	dec	rcx
	jnz	.loop	; no

.end:
	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rsi

	; return from the procedure
	ret

;===============================================================================
moko_document_reload:
	; save the original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; start the document at the given lines
	xor	ebx,	ebx
	mov	rcx,	qword [moko_document_show_from_line]

	; start
	jmp	.init

.loop:
	; display the next line of the document
	inc	rbx
	inc	rcx

.init:
	; display the "first" line of the document
	call	moko_line_number
	jc	.ready	; the remaining document lines have been displayed

	; end of the document space?
	cmp	rbx,	r9
	jb	.loop	; no

.ready:
	; clear the next lines of the document
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_line_clean_next_end - moko_string_line_clean_next
	mov	rsi,	moko_string_line_clean_next

.clean:
	; have the remaining document lines been cleared?
	cmp	rbx,	r9
	ja	.end	; yes

	; clear
	int	KERNEL_SERVICE

	; next line of the document
	inc	rbx

	; continue
	jmp	.clean

.end:
	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

;===============================================================================
moko_document_remove:
	; save the original registers
	push	rcx
	push	rsi
	push	rdi

	; number of characters to shift
	mov	rdi,	r10
	sub	rdi,	qword [moko_document_start_address]
	mov	rcx,	qword [moko_document_size]
	sub	rcx,	rdi

	; start in
	mov	rdi,	r10
	mov	rsi,	rdi
	inc	rsi

	; perform the operations
	rep	movsb

	; the number of characters in the document has decreased
	dec	qword [moko_document_size]

	; move the end of the document pointer
	dec	qword [moko_document_end_address]

	; the document status has been modified
	mov	byte [moko_modified_semaphore],	STATIC_TRUE

	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from the procedure
	ret

;===============================================================================
; entry:
;	ax - ASCII code of the character
;	bl - updating the global variables == STATIC_EMPTY
; exit:
;	CF flag - if the character is not printable
moko_document_insert:
	; save the original registers
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; insert a character at the end of the document?
	cmp	r10,	qword [moko_document_end_address]
	je	.at_end_of_document	; yes

	; are we inserting a newline character?
	cmp	ax,	STATIC_SCANCODE_NEW_LINE
	je	.no_insert_key	; ignore the insert key

	; is the Insert key active?
	cmp	byte [moko_key_insert_semaphore],	STATIC_FALSE
	je	.no_insert_key	; no

	; is there a newline character at this position now?
	cmp	byte [r10],	STATIC_SCANCODE_NEW_LINE
	je	.no_insert_key	; ignore the Insert key

	; swap the character in the line
	mov	byte [r10],	al

	; correct the variables
	jmp	.inserted

.no_insert_key:
	; move the document contents one character forward relative to the pointer

	; number of characters to move
	mov	rcx,	qword [moko_document_end_address]
	sub	rcx,	r10

	; start from the last character in the document
	mov	rdi,	qword [moko_document_end_address]
	mov	rsi,	rdi
	dec	rsi

	; perform the operation backwards
	std	; set the Direction Flag
	rep	movsb
	cld	; clear the Direction Flag

.at_end_of_document:
	; store the character in the document
	mov	byte [r10],	al

	; number of characters in the document + 1
	inc	qword [moko_document_size]

	; set the end of the document pointer one position further
	inc	qword [moko_document_end_address]

	; do not modify the line size?
	test	bl,	bl
	jnz	.end	; yes

	; increase the line size
	inc	r13

.inserted:
	; do not modify the properties of the current line and the cursor?
	test	bl,	bl
	jnz	.end	; yes

	; move the cursor position pointer in the document space to the next position
	inc	r10

	; move the cursor to the next column
	inc	r14

	; move the inner line position pointer to the next character
	inc	r11

	; save the last known inner line position pointer
	mov	qword [moko_document_line_index_last],	r11

	; has the cursor gone off screen?
	cmp	r14,	r8
	jb	.end	; no

	; move the cursor back to the previous column
	dec	r14

	; display the line contents from the next character
	inc	r12

	; save the last known pointer to the beginning of the displayed line
	mov	qword [moko_document_line_begin_last],	r12

.end:
	; the document status has been modified
	mov	byte [moko_modified_semaphore],	STATIC_TRUE

	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; return from the procedure
	ret

;===============================================================================
; entry:
;	rcx - size of the argument list in bytes
;	rsi - pointer to the argument string
moko_document_area:
	; save the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi

.retry:
	; fetch the output stream information
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	rdi,	moko_stream_meta
	int	KERNEL_SERVICE
	jc	.retry	; no current information, try once more

	; fetch from the stream meta data
	; information about the width and the height of the character space
	movzx	r8,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.width]
	movzx	r9,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.height]

	; shrink the document space by the menu and turn the value into a zero based one
	sub	r9,	MOKO_MENU_HEIGHT_char + STATIC_BYTE_SIZE_byte

	; were the arguments passed?
	test	rcx,	rcx
	jz	.no_args	; no

	; load and process the contents of the file
	call	moko_document_format
	jnc	.end	; executed correctly

.no_args:
	; prepare room for an empty document (4 KiB by default, about 4000 characters)
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	rcx,	MOKO_DOCUMENT_AREA_SIZE_default
	int	KERNEL_SERVICE
	jc	moko.end	; not enough memory

.set_up:
	; update the properties of the document
	mov	qword [moko_document_start_address],	rdi
	mov	qword [moko_document_end_address],	rdi

	; update the cursor positions inside the document
	mov	r10,	rdi

.end:
	; restore the original registers
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

;===============================================================================
; entry:
;	CF flag - if no new document was processed
;	rcx - number of characters in the string
;	rsi - pointer to the string
moko_document_format:
	; save the original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; fetch the file type
	mov	ax,	KERNEL_SERVICE_VFS_exist
	int	KERNEL_SERVICE
	jc	.end	; file not found

	; a plain text file?
	cmp	bl,	KERNEL_VFS_FILE_TYPE_regular_file
	je	.regular_file	; yes

	; not handled
	stc

	; end of handling
	jmp	.end

.regular_file:
	; load the given file
	mov	ax,	KERNEL_SERVICE_VFS_read
	int	KERNEL_SERVICE
	jc	.end	; file not found or it could not be loaded

	; save the size of the loaded document
	mov	qword [moko_document_size],	rcx

	; swap the document pointer
	xchg	qword [moko_document_start_address],	rdi

	; free the space of the old document?
	test	rdi,	rdi
	jz	.no	; no

	; if the document size has not been initialized
	test	rcx,	rcx
	jnz	.sized	; remainder

	; set the default
	mov	ecx,	STATIC_PAGE_SIZE_byte

.sized:
	; free the space of the old document
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_release
	int	KERNEL_SERVICE

.no:
	; analyse the contents of the document
	mov	rcx,	qword [moko_document_size]
	mov	rdi,	qword [moko_document_start_address]
	call	moko_document_analyze

	; display the document contents
	call	moko_document_reload

	; set the cursor to the beginning of the document
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	dword [moko_string_document_cursor.joint],	STATIC_EMPTY
	int	KERNEL_SERVICE

	; remember the information about displaying the message
	mov	byte [moko_status_semaphore],	STATIC_TRUE

.end:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret
