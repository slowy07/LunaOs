;===============================================================================

kernel_init_library:
	; map the logical library area
	mov	rax,	LIBRARY_BASE_address
	mov	bx,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_available
	mov	ecx,	kernel_init_library_file_end - kernel_init_library_file
	call	library_page_from_size
	call	kernel_page_map_logical

	; move the libraries to their target location
	mov	ecx,	(kernel_init_library_file_end - kernel_init_library_file) >> STATIC_DIVIDE_BY_8_shift
	mov	rsi,	kernel_init_library_file
	mov	rdi,	LIBRARY_BASE_address
	rep	movsq
