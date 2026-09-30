
zero_kernel:
	; disable the hardware interrupts on the PIC controller
	call	zero_pic_disable

	; disable processor exception and hardware interrupt handling
	cli

	; return information about the address and size of the memory map
	mov	ebx,	dword [rel zero_memory_map_address]

	; return information about the address of the ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK table
	mov	edx,	dword [rel zero_graphics_mode_info_block_address]

	; clear the remaining registers
	xor	eax,	eax
	xor	ecx,	ecx
	xor	esi,	esi
	xor	edi,	edi

	; run the kernel code
	jmp	0x0000000000100000
