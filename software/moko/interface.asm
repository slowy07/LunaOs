
moko_interface:
	; save the original registers
	push	rax
	push	rcx
	push	rsi

	; clear the screen and set it to the menu space position
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_at_menu_and_clear_screen_end - moko_string_cursor_at_menu_and_clear_screen
	mov	rsi,	moko_string_cursor_at_menu_and_clear_screen
	int	KERNEL_SERVICE

	; display
	mov	ecx,	moko_string_menu_end - moko_string_menu
	mov	rsi,	moko_string_menu
	int	KERNEL_SERVICE

	; set the cursor to the beginning of the document
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	int	KERNEL_SERVICE

	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret
