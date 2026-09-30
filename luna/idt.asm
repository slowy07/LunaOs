
ZERO_IDT_address equ 0x9000

ZERO_IDT_TYPE_exception equ 0x8E00
ZERO_IDT_TYPE_irq equ 0x8F00

struc ZERO_STRUCTURE_IDT_HEADER
	.limit resb 2
	.address resb 8
endstruc

zero_idt:
	; IDT address
	mov edi, ZERO_IDT_address

	; register all processor exceptions with the default handler
	mov rax, zero_idt_default_exception
	mov bx, ZERO_IDT_TYPE_exception
	mov ecx, 32 ; all processor exceptions
	call zero_idt_set

	; hook up the timer interrupt handler
	mov rax, zero_idt_clock
	mov bx, ZERO_IDT_TYPE_irq
	mov ecx, 1 ; all processor exceptions
	call zero_idt_set

	; register the remaining hardware interrupts with the default handler
	mov rax, zero_idt_default_interrupt
	mov ecx, 15 ; all processor exceptions
	call zero_idt_set

	; load the Interrupt Descriptor Table
	lidt [rel zero_idt_header]

	; enable interrupt handling
	sti

	; continue
	jmp zero_idt_end

zero_idt_default_exception:
	; return from a processor exception
	iretq

zero_idt_default_interrupt:
	; preserve the original registers
	push rax

	; acknowledge the interrupt
	mov al, 0x20
	out 0x20, al

	; restore the original registers
	pop rax

	; return from a hardware interrupt
	iretq

zero_idt_clock:
	; preserve the original registers
	push rax

	; increment microtime
	inc qword [rel zero_microtime]

	; acknowledge the interrupt
	mov al, 0x20
	out 0x20, al

	; restore the original registers
	pop rax

	; return from a hardware interrupt
	iretq

; in:
;	rax - logical address of the handler
;	bx - type: exception, interrupt (hardware, software)
;	rcx - number of consecutive records sharing the same handler
;	rdi - address of the record to modify in the Interrupt Descriptor Table
; out:
;	rdi - address of the next record in the Interrupt Descriptor Table
zero_idt_set:
	; preserve the original registers
	push rcx

.next:
	; preserve the handler address
	push rax

	; store the low 16 bits of the handler address into the table (bits 15...0)
	stosw

	; code descriptor selector (GDT), all routines are entered with ring0 privileges
	mov ax, 0x08
	stosw

	; type: exception, interrupt (hardware, software)
	mov ax, bx
	stosw

	; restore the handler address
	mov rax, qword [rsp]

	; shift bits 31...16 into ax
	shr rax, 16
	stosw

	; shift bits 63...32 into eax
	shr rax, 32
	stosd

	; reserved fields, left empty
	xor eax, eax
	stosd

	; restore the handler address
	pop rax

	; process the remaining records
	dec rcx
	jnz .next

	; restore the original registers
	pop rcx

	; return from the routine
	ret

zero_idt_end:
