
tm_stream_info:
	; fetch the output stream information
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rdi,	tm_stream_meta
	int	KERNEL_SERVICE
	jc	tm_stream_info	; no current information

	; return from the procedure
	ret

	macro_debug	"software: tm_stream_info"
