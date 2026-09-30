
struc KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP
	.address resb 8
	.limit resb 8
	.type resb 4
	.SIZE:
endstruc

; input:
;	ebx - pointer to the memory map array
kernel_init_memory:
	; find the memory area starting at the KERNEL_BASE_address address
	cmp qword [ebx + KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.address], KERNEL_BASE_address
	je .found ; found

	; next entry from the memory map array
	add ebx, KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.SIZE

	; end of the entries?
	cmp qword [ebx], STATIC_EMPTY
	jne kernel_init_memory ; no

	; error message
	mov rsi, kernel_init_string_error_memory
	call kernel_panic

.found:
	; fetch the area size and turn it into a number of pages
	mov rcx, qword [rbx + KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.limit]
	shr rcx, STATIC_DIVIDE_BY_PAGE_shift ; we drop the remainder (a partial page is useless)

	; save the information about the number of available pages (total and current)
	mov qword [rel kernel_page_total_count], rcx
	mov qword [rel kernel_page_free_count], rcx

	; we put the binary memory map behind the kernel code
	mov rdi, kernel_end
	call library_page_align_up

	; save the address of the kernel binary memory map
	mov qword [rel kernel_memory_map_address], rdi

	; turn the number of pages into "sets" of 8 bits
	shr rcx, STATIC_DIVIDE_BY_8_shift ; in this case we can lose up to 7 pages
							; used to simplify the code

	; save the number of pages
	push rcx

	; clear the binary memory map area
	call library_page_from_size
	call kernel_page_drain_few

	; restore the number of pages
	pop rcx

	; fill in the binary memory map
	mov al, STATIC_MAX_unsigned
	rep stosb

	; save the address of the end of the binary memory map
	mov qword [rel kernel_memory_map_address_end], rdi

	; mark the pages holding the kernel code and the binary memory map as used

	; compute the size of the used area in pages
	call library_page_align_up
	sub rdi, KERNEL_BASE_address
	shr rdi, STATIC_DIVIDE_BY_PAGE_shift

	; mark the first N pages in the binary memory map as used
	mov rcx, rdi
	mov rsi, qword [rel kernel_memory_map_address]
	call kernel_memory_secure
