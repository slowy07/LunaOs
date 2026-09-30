
KERNEL_IO_APIC_ioregsel equ 0x00
KERNEL_IO_APIC_iowin equ 0x10
KERNEL_IO_APIC_iowin_low equ 0x00
KERNEL_IO_APIC_iowin_high equ 0x01

KERNEL_IO_APIC_TRIGER_MODE_level equ 1000000000000000b

kernel_io_apic_base_address dq STATIC_EMPTY

; input:
;	eax - relative address of the vector in the IDT table
;	ebx - register of the I/O APIC controller
kernel_io_apic_connect:
	; preserve the original registers
	push rax
	push rbx
	push rdi

	; point the pointer at the I/O APIC table area
	mov rdi, qword [rel kernel_io_apic_base_address]

	; lower part of the register
	add ebx, KERNEL_IO_APIC_iowin_low
	mov dword [rdi + KERNEL_IO_APIC_ioregsel], ebx

	; store the information about the lower part of the vector address
	mov dword [rdi + KERNEL_IO_APIC_iowin], eax

	; upper part of the register
	add ebx, KERNEL_IO_APIC_iowin_high - KERNEL_IO_APIC_iowin_low
	mov dword [rdi + KERNEL_IO_APIC_ioregsel], ebx

	; store the information about the upper part of the vector address
	shr rax, STATIC_MOVE_HIGH_TO_EAX_shift
	mov dword [rdi + KERNEL_IO_APIC_iowin], eax

	; restore the original registers
	pop rdi
	pop rbx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_io_apic_connect"
