;===============================================================================

	%include	"software/hello/config.asm"

;===============================================================================
hello:
	; display the greeting
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	cl,	hello_string_end - hello_string
	mov	rsi,	hello_string
	int	KERNEL_SERVICE

	; terminate the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: hello"

	%include	"software/hello/data.asm"
