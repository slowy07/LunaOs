
shell_header:
	; save the original registers
	push rax
	push rcx
	push rsi

	; ask the stream owner to change the window title (if there is one)
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, shell_string_console_header_end - shell_string_console_header
	mov rsi, shell_string_console_header
	int KERNEL_SERVICE

	; restore the original registers
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret
