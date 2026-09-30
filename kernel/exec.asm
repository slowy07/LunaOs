
KERNEL_EXEC_FLAG_accept_childrens equ 00000001b ; accept the streams of the child processes on the standard input
KERNEL_EXEC_FLAG_forward_out equ 00000010b ; redirect the output of the parent to the input of the child process

; input:
;\trcx - number of characters representing the name of the program to run
;\trsi - pointer to the program name together with the arguments
;\trdi - pointer to the file spool
;\tr8 - size of the arguments in Bytes
; output:
;\tCF flag - an error occurred
;\trax - error code, if the CF flag is raised
;\trcx - PID of the new process
;\trdi - pointer to the task structure
kernel_exec:
	; preserve the original registers
	push rdx
	push rsi
	push rbp
	push r8
	push r11
	push r12
	push r13
	push r14
	push rax
	push rbx
	push rcx
	push rdi

	; compute the number of pages needed to load the file into the memory
	mov rcx, qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size]
	call library_page_from_size

	; save the size of the code area in Bytes
	mov r12, rcx

	; limit the number of the arguments passed to the process
	mov eax, KERNEL_ERROR_memory_low ; error code
	cmp r8, STATIC_PAGE_SIZE_byte ; initialised size of the process stack in Bytes
	ja .error ; overflow

	; reserve the number of pages needed to initialise the process
	add rcx, 15 ; 14 pages for the process area, +1 to extend the serpentine if there is no space
	call kernel_page_secure
	jc .error ; not enough memory

	; tell all the dependent procedures to use the reserved pages
	mov rbp, rcx

	; create the PML4 table of the process
	call kernel_memory_alloc_page
	call kernel_page_drain

	; the page has been used for paging
	inc qword [rel kernel_page_paged_count]

	; save the address
	mov r11, rdi

	; prepare the space for the code area of the process
	mov rax, SOFTWARE_BASE_address
	mov bx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user
	mov rcx, r12
	call kernel_page_map_logical
	jc .error

	; prepare the space for the binary memory map of the process
	shl r12, STATIC_PAGE_SIZE_shift
	add rax, r12 ; behind the code area of the process
	and bx, ~KERNEL_PAGE_FLAG_user ; accessible from the kernel side only
	mov rcx, KERNEL_MEMORY_MAP_SIZE_page
	call kernel_page_map_logical

	; save the direct address of the binary memory map of the process
	mov r13, rax

	; fetch the physical address of the page destined for the binary memory map of the process
	mov rdi, qword [r8]
	and di, STATIC_PAGE_mask ; remove the flags from the page address
	push rdi ; save

	; clear the binary memory map of the process
	mov rax, STATIC_MAX_unsigned
	mov ecx, (KERNEL_MEMORY_MAP_SIZE_page << STATIC_PAGE_SIZE_shift) >> STATIC_DIVIDE_BY_QWORD_shift
	rep stosq

	; mark in the binary memory map of the process the area taken by the code and the binary map
	pop rsi
	mov rcx, r12
	shr rcx, STATIC_PAGE_SIZE_shift
	add rcx, KERNEL_MEMORY_MAP_SIZE_page
	call kernel_memory_secure

	; prepare the space for the stack of the process
	mov rax, KERNEL_TASK_STACK_address
	or bx, KERNEL_PAGE_FLAG_user
	mov rcx, SOFTWARE_STACK_limit
	call kernel_page_map_logical
	jc .error

	; save the passed arguments on the stack of the process

	; size of the list of the passed arguments in Bytes
	mov rax, qword [rsp + STATIC_QWORD_SIZE_byte * 0x08]

	; physical address of the context stack page
	mov rdi, qword [r8]
	and di, STATIC_PAGE_mask ; remove the flags from the address

	; move the pointer N Bytes deep into the area
	add rdi, STATIC_PAGE_SIZE_byte
	sub rdi, rax
	and di, 0xFFF8 ; bring the pointer to a full address

	; space for the data size counter on the stack of the process
	sub rdi, STATIC_QWORD_SIZE_byte

	; remember the address of the top of the stack of the process
	mov r14, KERNEL_TASK_STACK_address
	or r14w, di

	; put the data size on the stack for the process
	stosq

	; no argument list?
	test rax, rax
	jz .no_arguments ; yes

	; set the pointer to the beginning of the argument list
	mov rcx, rax ; counter of the data to copy
	mov rsi, qword [rsp + STATIC_QWORD_SIZE_byte * 0x0A]
	add rsi, qword [rsp + STATIC_QWORD_SIZE_byte]
	rep movsb ; copy

.no_arguments:
	; prepare the space for the context stack (belongs to the kernel)
	mov rax, SOFTWARE_BASE_address - KERNEL_STACK_SIZE_byte
	mov rbx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov rcx, KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call kernel_page_map_logical
	jc .error

	; map the kernel address space
	mov rsi, qword [rel kernel_page_pml4_address]
	mov rdi, r11
	call kernel_page_merge

	; back up to the start of the task context stack, the prepared return data from the "kernel_task" hardware interrupt
	mov rdi, qword [r8]
	and di, STATIC_PAGE_mask ; remove the flags of the PML1 table record
	add rdi, STATIC_PAGE_SIZE_byte - ( STATIC_QWORD_SIZE_byte * 0x05 ) ; put back 5 registers

	; RIP
	mov rax, SOFTWARE_BASE_address
	stosq

	; CS
	mov rax, KERNEL_STRUCTURE_GDT.cs_ring3 | 0x03
	stosq ; store

	; EFLAGS
	mov rax, KERNEL_TASK_EFLAGS_default
	stosq ; store

	; RSP
	mov rax, r14
	stosq ; store

	; DS
	mov rax, KERNEL_STRUCTURE_GDT.ds_ring3 | 0x03
	stosq ; store

	; restore the pointer to the file spool
	mov rsi, qword [rsp]

	; switch the memory space to the process
	mov rax, cr3
	mov cr3, r11

	; load the program code into the memory space of the process
	mov rdi, SOFTWARE_BASE_address
	call kernel_vfs_file_read
	jc .error ; the file could not be loaded into the memory space

	; restore the memory space to the parent
	mov cr3, rax

	; insert the process into the task queue
	mov eax, KERNEL_ERROR_memory_low ; error code
	movzx ecx, byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.length]
	add rsi, KERNEL_VFS_STRUCTURE_KNOT.name
	mov rbx, (SOFTWARE_BASE_address - STATIC_PAGE_SIZE_byte) - (STATIC_QWORD_SIZE_byte * 0x14)
	call kernel_task_add
	jc .error

	; size of the area taken by the process in pages
	shr r12, STATIC_DIVIDE_BY_PAGE_shift
	inc r12 ; area of the binary memory map of the process in pages
	add r12, SOFTWARE_STACK_limit ; together with the stack area
	mov qword [rdi +KERNEL_TASK_STRUCTURE.memory], r12

	; complete the entry with the address of the binary memory map of the process and its size
	add r13, qword [rel kernel_memory_high_mask]
	mov qword [rdi + KERNEL_TASK_STRUCTURE.map], r13
	mov qword [rdi + KERNEL_TASK_STRUCTURE.map_size], (KERNEL_MEMORY_MAP_SIZE_page << STATIC_PAGE_SIZE_shift) << STATIC_MULTIPLE_BY_8_shift

	; release the unused reserved pages
	add qword [rel kernel_page_free_count], rbp
	sub qword [rel kernel_page_reserved_count], rbp

	; return the PID of the created task
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx

	; return the pointer to the task structure
	mov qword [rsp], rdi

	; end of the procedure handling
	jmp .end

.error:
	; return the error code
	mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x04], rax

.end:
	; restore the original registers
	pop rdi
	pop rcx
	pop rbx
	pop rax
	pop r14
	pop r13
	pop r12
	pop r11
	pop r8
	pop rbp
	pop rsi
	pop rdx

	; return from the procedure
	ret

	macro_debug "kernel_exec"
