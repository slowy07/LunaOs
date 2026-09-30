
; NOTE:
;	registers destroyed
console_meta:
	; current cursor position
	mov	ax,	word [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x]
	mov	word [console_stream_meta + CONSOLE_STRUCTURE_STREAM_META.x],	ax
	mov	ax,	word [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	mov	word [console_stream_meta + CONSOLE_STRUCTURE_STREAM_META.y],	ax

	; save the original registers
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_in
	mov	rsi,	console_stream_meta
	int	KERNEL_SERVICE

	; return from the procedure
	ret
