;===============================================================================

	; prepare the space for the data coming from the standard input
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	ecx,	KERNEL_STREAM_SIZE_byte
	int	KERNEL_SERVICE
	jc	console.close	; not enough memory space

	; save the buffer address
	mov	qword [console_cache_address],	rdi

	; create the window
	mov	rsi,	console_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	console.close	; not enough memory space

	; calculate the address of the data space pointer of the "terminal" element
	movzx	eax,	word [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	movzx	ecx,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mul	rcx
	mov	cx,	word [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	add	rax,	rcx
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; complete the "terminal" table with the space address
	mov	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.address],	rax

	; complete the "terminal" table with the window scanline
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]
	mov	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.scanline_byte],	rax

	; initialize the space of the "terminal" element
	mov	r8,	console_terminal_table
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal

	; run the system shell
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent	; redirect the child output to the parent input
	mov	ecx,	console_shell_file_end - console_shell_file
	mov	rsi,	console_shell_file
	xor	r8,	r8	; no arguments passed
	int	KERNEL_SERVICE
	jc	console.close	; failed to start the shell process

	; save the shell PID
	mov	qword [console_shell_pid],	rcx

	; display the window
	mov	al,	KERNEL_WM_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ
