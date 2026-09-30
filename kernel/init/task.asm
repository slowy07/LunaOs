
kernel_init_task:
	; fetch the highest Local APIC identifier
	movzx	ecx,	byte [rel kernel_init_apic_id_highest]
	inc	cx	; change the counting to start at 1 (we normally count from 0)

	; turn the identifier into the size in bytes of the active task list of the individual logical processors
	shl	ecx,	STATIC_MULTIPLE_BY_8_shift

	; turn it into pages
	call	library_page_from_size

	; reserve an area of the given size
	call	kernel_memory_alloc
	jc	kernel_panic_memory

	; save the address of the active task list
	call	kernel_page_drain_few	; clear the area
	mov	qword [rel kernel_task_active_list],	rdi

	; point at the start of the active task list
	mov	rsi,	rdi

	; prepare room for the task queue
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; clear the task queue
	call	kernel_page_drain

	; remember the address of the start of the task queue
	mov	qword [rel kernel_task_address],	rdi

	; link the end of the queue to the start (RoundRobin)
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rdi

	; fetch the ID of the BSP
	call	kernel_apic_id_get

	; insert the first entry from the task queue into the active task list
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	mov	qword [rsi + rax],	rdi

	; put the kernel in as the first process in the task queue
	mov	ebx,	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_secured | KERNEL_TASK_FLAG_processing
	mov	ecx,	kernel_init_string_name_end - kernel_init_string_name
	mov	rsi,	kernel_init_string_name
	mov	r11,	qword [rel kernel_page_pml4_address]
	call	kernel_task_add

	; set the kernel working directory to /
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.knot],	kernel_vfs_magicknot

	; hook up the active task switch handler
	; under the timer interrupt of the controller, the APIC of the BSP/logical processor
	mov	rax,	KERNEL_APIC_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	kernel_task
	call	kernel_idt_mount
