
kernel_init_stream:
	; prepare room for an empty pipe table
	call kernel_memory_alloc_page
	call kernel_page_drain

	; save the address of the pipe table
	mov qword [rel kernel_stream_address], rdi

	; set the next table chunk pointer to the start
	mov qword [rdi + STATIC_STRUCTURE_BLOCK.link], rdi

	; prepare the default output pipe (stdout, stderr, stdlog)
	call kernel_stream

	; save the pointer to the default output pipe
	mov qword [rel kernel_stream_out_default], rsi
