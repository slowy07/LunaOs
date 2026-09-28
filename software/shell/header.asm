;===============================================================================

;===============================================================================
shell_header:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; poproś właściciela strumienia o zmianę tytułu okna (jeśli istnieje)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_string_console_header_end - shell_string_console_header
	mov	rsi,	shell_string_console_header
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
