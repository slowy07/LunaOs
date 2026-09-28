;===============================================================================

;===============================================================================
; input:
;	rsi - pointer to the data for the thread
;	rdi - pointer to the start of the thread code
kernel_thread:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	r8
	push	r11

	; prepare space for a new page table for the thread
	call	kernel_memory_alloc_page
	jc	.end	; no space

	; clear the PML4 table
	call	kernel_page_drain

	; create a new context stack for the thread
	mov	rax,	KERNEL_STACK_address
	mov	ebx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	ecx,	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	mov	r11,	rdi
	call	kernel_page_map_logical

	; back up to the start of the task context stack, the prepared return data from the "kernel_task" hardware interrupt
	mov	rdi,	qword [r8]
	and	di,	STATIC_PAGE_mask	; remove the flags of the PML1 table record
	add	rdi,	STATIC_PAGE_SIZE_byte - ( STATIC_QWORD_SIZE_byte * 0x05 )	; put back 5 registers

	; RIP
	mov	rax,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	stosq

	; CS
	mov	rax,	KERNEL_STRUCTURE_GDT.cs_ring0
	stosq	; store

	; EFLAGS
	mov	rax,	KERNEL_TASK_EFLAGS_default
	stosq	; store

	; RSP
	mov	rax,	KERNEL_STACK_pointer
	stosq	; store

	; DS
	mov	rax,	KERNEL_STRUCTURE_GDT.ds_ring0
	stosq	; store

	; set the pointer to the data for the thread
	mov	qword [rdi - STATIC_QWORD_SIZE_byte * 0x0B],	rsi

	; map the address space of the parent process
	mov	rsi,	cr3
	mov	rdi,	r11
	call	kernel_page_merge

	; insert the task as suspended into the queue of the least loaded logical processor
	mov	bx,	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_thread | KERNEL_TASK_FLAG_secured
	call	kernel_task_add

.end:
	; restore the original registers
	pop	rdi
	pop	r8
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_thread"
