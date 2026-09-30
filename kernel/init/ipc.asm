
kernel_init_ipc:
	; prepare room for the message list
	mov ecx, KERNEL_IPC_SIZE_page_default
	call kernel_memory_alloc

	; clear the list
	call kernel_page_drain_few

	; save the address of the start of the area
	mov qword [rel kernel_ipc_base_address], rdi

	; link the end of the area to the start
	mov qword [rdi + STATIC_STRUCTURE_BLOCK.link], rdi
