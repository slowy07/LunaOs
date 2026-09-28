;===============================================================================

struc	KERNEL_STRUCTURE_IDT_HEADER
	.limit				resb	2
	.address			resb	8
endstruc

kernel_init_idt:
	; reserve room for the Interrupt Descriptor Table
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; clear the IDT table and save its address
	call	kernel_page_drain
	mov	qword [rel kernel_idt_header + KERNEL_STRUCTURE_IDT_HEADER.address],	rdi

	;-----------------------------------------------------------------------
	; default processor exception handler
	mov	rax,	kernel_idt_exception_default
	mov	bx,	KERNEL_IDT_TYPE_exception
	mov	ecx,	32	; all processor exceptions
	call	kernel_idt_update

	;-----------------------------------------------------------------------
	; default hardware interrupt handler
	mov	rax,	kernel_idt_interrupt_hardware
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	16	; default number of PIC hardware interrupts
	call	kernel_idt_update

	;-----------------------------------------------------------------------
	; default hardware interrupt handler
	mov	rax,	kernel_idt_interrupt_software
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	ecx,	208	; default number of PIC hardware interrupts
	call	kernel_idt_update

	;-----------------------------------------------------------------------
	; hook up the "General Protection Fault" handler
	mov	eax,	0x0D
	mov	bx,	KERNEL_IDT_TYPE_exception
	mov	rdi,	kernel_idt_exception_general_protection_fault

	;-----------------------------------------------------------------------
	; hook up the "Page Fault" handler
	mov	eax,	0x0E
	mov	bx,	KERNEL_IDT_TYPE_exception
	mov	rdi,	kernel_idt_exception_page_fault

	;-----------------------------------------------------------------------
	; hook up the software interrupt handler
	mov	eax,	0x40
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	rdi,	kernel_service
	call	kernel_idt_mount

	;-----------------------------------------------------------------------
	; hook up the "spurious interrupt" handler
	mov	eax,	0xFF
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	kernel_idt_spurious_interrupt
	call	kernel_idt_mount

	;-----------------------------------------------------------------------
	; load the Interrupt Descriptor Table
	lidt	[rel kernel_idt_header]
