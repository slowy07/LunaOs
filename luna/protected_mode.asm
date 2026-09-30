
zero_protected_mode:
	; disable interrupts if the boot program is in 16-bit mode
	; they will be restored afterwards
	cli

	; load the global descriptor table for 32-bit mode
	lgdt [zero_protected_mode_header_gdt_32bit]

	; switch the processor to protected mode
	mov eax, cr0
	bts eax, 0 ; set the first bit of CR0
	mov cr0, eax

	; jump to the 32-bit code
	jmp long 0x0008:zero_protected_mode_entry

; we keep all tables at a full address
align 0x10
zero_protected_mode_table_gdt_32bit:
	; null descriptor
	dq 0x0000000000000000
	; code descriptor
	dq 0000000011001111100110000000000000000000000000001111111111111111b
	; data descriptor
	dq 0000000011001111100100100000000000000000000000001111111111111111b
zero_protected_mode_table_gdt_32bit_end:

zero_protected_mode_header_gdt_32bit:
	dw zero_protected_mode_table_gdt_32bit_end - zero_protected_mode_table_gdt_32bit - 0x01
	dd zero_protected_mode_table_gdt_32bit

; 32-bit boot program code ==========================================
[bits 32]

zero_protected_mode_entry:
	; point the data, extra and stack descriptors at the data space
	mov ax, 0x10
	mov ds, ax ; data segment
	mov es, ax ; extra segment
	mov ss, ax ; stack segment
