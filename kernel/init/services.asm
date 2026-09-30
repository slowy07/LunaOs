
struc KERNEL_INIT_STRUCTURE_SERVICE
	.pointer resb 8
	.size resb 8
	.length resb 1
	.name:
endstruc

kernel_init_services:
	; point at the start of the list of services to start
	mov rsi, kernel_init_services_list

.loop:
	; reserve room for the service PML4 table
	call kernel_memory_alloc_page
	jc kernel_panic_memory

	; remove every entry from the table
	call kernel_page_drain

	; map the area for the service stack
	mov rax, KERNEL_STACK_address
	mov rbx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov rcx, KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	mov r11, rdi
	call kernel_page_map_logical

	; place the prepared hardware interrupt return data on the top of the service stack
	mov rdi, qword [r8] ; fetch the start address of the stack area from the PML1 table row
	and di, STATIC_PAGE_mask ; remove the area flags
	add rdi, STATIC_PAGE_SIZE_byte - ( STATIC_QWORD_SIZE_byte * 0x05 ) ; push 5 registers

	; RIP
	mov rax, qword [rsi + KERNEL_INIT_STRUCTURE_SERVICE.pointer] ; service entry point
	stosq

	; CS, all services run in the kernel space
	mov rax, KERNEL_STRUCTURE_GDT.cs_ring0
	stosq

	; EFLAGS, all flags cleared, interrupts enabled
	mov rax, KERNEL_TASK_EFLAGS_default
	stosq

	; RSP, stack top pointer, once the service has started
	mov rax, KERNEL_STACK_pointer
	stosq

	; DS
	mov rax, KERNEL_STRUCTURE_GDT.ds_ring0
	stosq

	; save the list pointer
	push rsi

	; map the kernel memory area into the service
	mov rsi, qword [rel kernel_page_pml4_address]
	mov rdi, r11
	call kernel_page_merge

	; restore the list pointer
	pop rsi

	; put the service on the task queue
	mov rbx, KERNEL_STACK_pointer - (STATIC_QWORD_SIZE_byte * 0x14)
	movzx ecx, byte [rsi + KERNEL_INIT_STRUCTURE_SERVICE.length]
	push rcx ; remember the number of characters in the process name
	add rsi, KERNEL_INIT_STRUCTURE_SERVICE.name
	call kernel_task_add

	; attach the default output stream
	mov rax, qword [rel kernel_stream_out_default]
	mov qword [rdi + KERNEL_TASK_STRUCTURE.out], rax

	; number of processes using the stream
	inc qword [rax + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

	; mark the task as active and a service
	or word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_service

	; store the process size information in pages
	mov rcx, qword [rsi + (KERNEL_INIT_STRUCTURE_SERVICE.size - KERNEL_INIT_STRUCTURE_SERVICE.name)]
	call library_page_from_size
	add rcx, KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift ; together with the stack area
	mov qword [rdi + KERNEL_TASK_STRUCTURE.memory], rcx

	; end of the table?
	pop rcx ; restore the number of characters in the process name
	add rsi, rcx
	cmp qword [rsi], STATIC_EMPTY
	jne .loop ; nie
