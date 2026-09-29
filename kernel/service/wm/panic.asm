;===============================================================================

kernel_wm_string_error_memory_low	db	"DESU: no enough memory."
kernel_wm_string_error_memory_low_end:

;===============================================================================
kernel_wm_panic_memory_low:
	; display the error message
	mov	ecx,	kernel_wm_string_error_memory_low_end - kernel_wm_string_error_memory_low
	mov	rsi,	kernel_wm_string_error_memory_low
	call	kernel_video_string

	; stop further work of the service
	jmp	$
