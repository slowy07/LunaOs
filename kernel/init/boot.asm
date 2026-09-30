
; 16 bit logical processor boot code ================
[BITS 16]

; code position within the CS segment
[ORG 0x7000]

boot:
	; prepare the 32 bit production environment

	; disable the interrupts
	cli

	; set the code segment (CS) address to the start of physical memory
	jmp	0x0000:.repair_cs

.repair_cs:
	; set the data (DS), extra (ES) and stack (SS) segment addresses to the start of physical memory
	xor	ax,	ax
	mov	ds,	ax	; data segment
	mov	es,	ax	; extra segment

	; clear the Direction Flag
	cld

	; load the global descriptor table for 32 bit mode
	lgdt	[boot_header_gdt_32bit]

	; switch the processor into protected mode
	mov	eax,	cr0
	bts	eax,	0	; set the first bit of the cr0 register
	mov	cr0,	eax

	; jump to the 32 bit boot code
	jmp	long 0x0008:boot_protected_mode

align 0x10	; we keep all the tables under a full address
boot_table_gdt_32bit:
	; null descriptor
	dq	0x0000000000000000
	; code descriptor
	dq	0000000011001111100110000000000000000000000000001111111111111111b
	; data descriptor
	dq	0000000011001111100100100000000000000000000000001111111111111111b
boot_table_gdt_32bit_end:

boot_header_gdt_32bit:
	dw	boot_table_gdt_32bit_end - boot_table_gdt_32bit - 0x01
	dd	boot_table_gdt_32bit

; 32 bit logical processor boot code ================
[BITS 32]

boot_protected_mode:
	; set the data, extra and stack descriptors to the data area
	mov	ax,	0x10
	mov	ds,	ax	; data segment
	mov	es,	ax	; extra segment

	; load the global descriptor table for 64 bit mode
	lgdt	[boot_header_gdt_64bit]

	; enable the NX/PAE, PGE and OSFXSR bits in the CR4 register
	mov	eax,	1010100000b	; NX (bit 5) - no-execute protection in a page, or physical memory addressing up to 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - paging support
					; OSFXSR (bit 9) - support for the XMM0-15 registers

	; load the physical address of the boot PML4 table into CR3
	mov	eax,	0x0000A000	; address dependent on the boot page tables Zero
	mov	cr3,	eax

	; enable the LME mode (bit 9) in the EFER MSR
	mov	ecx,	0xC0000080	; EFER MSR address
	rdmsr
	or	eax,	100000000b
	wrmsr

	; enable the PE and PG bits in the cr0 register
	mov	eax,	cr0
	or	eax,	0x80000001	; PE (bit 0) - leave real mode,
	mov	cr0,	eax		; PG (bit 31) - paging

	; jump to the 64 bit logical processor boot code
	jmp	0x0008:boot_long_mode

; all the tables at an address aligned to 0x08 bytes
align 0x10
boot_table_gdt_64bit:
	; null descriptor
	dq	0x0000000000000000
	; code descriptor
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; data descriptor
	dq	0000000000100000100100100000000000000000000000000000000000000000b
boot_table_gdt_64bit_end:

boot_header_gdt_64bit:
	dw	boot_table_gdt_64bit_end - boot_table_gdt_64bit - 0x01
	dd	boot_table_gdt_64bit

; 64 bit logical processor boot code ================
[BITS 64]

boot_long_mode:
	; jump to the kernel code
	jmp	0x0000000000100000

; end of the logical processor boot code
boot_end:
