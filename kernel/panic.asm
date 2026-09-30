
kernel_panic_memory:
	; error message
	mov	rsi,	kernel_init_string_error_memory_low

; input:
;	rbp - pointer to the null-terminated string
kernel_panic:
	; output the message on the COM1 port
	call	driver_serial_send

	; stop any further code execution
	jmp	$

	macro_debug	"kernel_panic"
