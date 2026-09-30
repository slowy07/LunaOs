

	; the stack is unavailable at this point!

	; GDT

	; load the Global Descriptor Table
	lgdt [rel kernel_gdt_header]

	; TSS

	; fetch the logical processor identifier
	mov rax, qword [rel kernel_apic_base_address]
	mov dword [rax + KERNEL_APIC_TP_register], STATIC_EMPTY
	mov eax, dword [rax + KERNEL_APIC_ID_register]
	shr eax, 24 ; shift the bits from 24..31 to 0..7

	; load the Task State Segment descriptor for the given logical processor
	shl eax, STATIC_MULTIPLE_BY_16_shift ; compute the offset in the GDT for the TSS selector
	add ax, word [rel kernel_gdt_tss_bsp_selector] ; adjust the offset relative to the BSP descriptor
	mov word [rel kernel_gdt_tss_cpu_selector], ax
	ltr word [rel kernel_gdt_tss_cpu_selector]

	; IDT

	; load the Interrupt Descriptor Table
	lidt [rel kernel_idt_header]

	; ONLY ONE LOGICAL PROCESSOR AT A TIME MAY RUN THE PAGING PROCEDURE BELOW
.wait: ;=======================================================================
	mov al, STATIC_TRUE
	xchg byte [rel kernel_init_ap_semaphore], al
	test al, al ; check whether access has been obtained
	jz .wait ; locked, try once more

	; Page

	; temporarily point at the page tables of the BSP
	mov rax, qword [rel kernel_page_pml4_address]
	mov cr3, rax

	; set the temporary stack top pointer for the logical processor
	mov rsp, KERNEL_STACK_TEMPORARY_pointer

	; reserve room for the PML4 table of the logical processor
	call kernel_memory_alloc_page
	jc kernel_panic_memory

	; clear the PML4 table
	call kernel_page_drain

	; page used for the page tables
	inc qword [rel kernel_page_paged_count]

	; prepare a separate stack/context for the logical processor
	mov rax, KERNEL_STACK_address
	mov ebx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov ecx, KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	mov r11, rdi ; add an entry to the PML4 of the logical processor
	xor ebp, ebp ; no pages reserved for this purpose
	call kernel_page_map_logical

	; map the rest of the memory space following the BSP
	mov rsi, qword [rel kernel_page_pml4_address]
	call kernel_page_merge

	; reload the paging of the logical processor
	mov rax, rdi
	mov cr3, rax

	; we set the stack top pointer to the end of the stack
	mov rsp, KERNEL_STACK_pointer

	; release access to the procedure
	mov byte [rel kernel_init_ap_semaphore], STATIC_FALSE

	; APIC
	call kernel_init_apic

	; TASK - assign the first task to be processed for the logical processor

	; clear the DF flag
	cld

	; fetch the logical processor identifier
	call kernel_apic_id_get

	; point at the position of the current task for the logical processor
	mov rbx, rax
	shl rbx, STATIC_MULTIPLE_BY_8_shift
	mov rsi, qword [rel kernel_task_active_list]

	; point at the start of the task queue
	mov rdi, qword [rel kernel_task_address]

	; logical processor initialised
	inc byte [rel kernel_init_ap_count]

	; assign the first task for the logical processor
	jmp kernel_task.ap_entry
