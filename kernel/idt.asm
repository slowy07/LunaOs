
KERNEL_IDT_IRQ_offset			equ	0x20

KERNEL_IDT_TYPE_exception		equ	0x8E00
KERNEL_IDT_TYPE_irq			equ	0x8F00
KERNEL_IDT_TYPE_isr			equ	0xEF00

; input:
;	rax - interrupt number
;	rbx - interrupt identifier (exception, hardware or process)
;	rdi - address of the interrupt handler
kernel_idt_mount:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; put the registers in their places
	xchg	rax,	rdi

	; compute the offset to the record of the interrupt number
	shl	rdi,	STATIC_MULTIPLE_BY_16_shift
	add	rdi,	qword [rel kernel_idt_header + KERNEL_STRUCTURE_IDT_HEADER.address]

	; interrupt handler
	mov	rcx,	1	; attach the handler to a single record
	call	kernel_idt_update

	; restore the original registers
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_idt_mount"

; input:
;	rax - logical address of the handler
;	bx - type: exception, interrupt (hardware, software)
;	rcx - number of consecutive records with the same handler
;	rdi - address of the record to modify in the Interrupt Descriptor Table
; output:
;	rdi - address of the next record in the Interrupt Descriptor Table
kernel_idt_update:
	; preserve the original registers
	push	rcx

.next:
	; save the address of the handler
	push	rax

	; load the handler address into the table (bits 15...0)
	stosw

	; code descriptor selector (GDT), all procedures are called with ring0 privileges
	mov	ax,	KERNEL_STRUCTURE_GDT.cs_ring0
	stosw

	; type: exception, interrupt (hardware, software)
	mov	ax,	bx
	stosw

	; restore the address of the handler
	mov	rax,	qword [rsp]

	; move bits 31...16 into ax
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift
	stosw

	; move bits 63...32 into eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	stosd

	; reserved fields, left empty
	xor	eax,	eax
	stosd

	; restore the address of the handler
	pop	rax

	; process the remaining records
	dec	rcx
	jnz	.next

	; restore the original registers
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_idt_update"

; default handler of a processor exception
kernel_idt_exception_default:
	; dump the faulting context on the COM1 port
	call	kernel_debug_dump

	; break into the Bochs debugger
	xchg	bx,bx

	nop

	; stop any further code execution for the current process
	jmp	$

	macro_debug	"kernel_idt_exception_default"

kernel_idt_exception_general_protection_fault:
	; dump the faulting context on the COM1 port
	call	kernel_debug_dump

	; break into the Bochs debugger
	xchg	bx,bx

	nop
	nop

	; stop any further code execution for the current process
	jmp	$

	macro_debug	"kernel_idt_exception_general_protection_fault"

kernel_idt_exception_page_fault:
	; dump the faulting context on the COM1 port
	call	kernel_debug_dump

	; preserve the original registers
	push	rcx
	push	rsi

	; break into the Bochs debugger
	xchg	bx,bx

	nop
	nop
	nop

	; stop any further code execution for the current process
	jmp	$

	macro_debug	"kernel_idt_exception_page_fault"

; default handler of a hardware interrupt
kernel_idt_interrupt_hardware:
	; preserve the original registers
	push	rdi

	; inform the APIC that the current hardware interrupt has been handled
	mov	rdi,	qword [rel kernel_apic_base_address]
	mov	dword [rdi + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; restore the original registers
	pop	rdi

	; return to the task
	iretq

	macro_debug	"kernel_idt_interrupt_hardware"

; handler of an invalid software interrupt
kernel_idt_interrupt_software:
	; return the error information
	or	word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags],	KERNEL_TASK_EFLAGS_cf

	; return to the task
	iretq

	macro_debug	"kernel_idt_interrupt_software"

; handler of the "unhandled" interrupt
kernel_idt_spurious_interrupt:
	; return to the task
	iretq

	macro_debug	"kernel_idt_spurious_interrupt"
