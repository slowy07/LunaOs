
ZERO_LONG_MODE_PML4_address		equ	0xA000	; physical address

ZERO_LONG_MODE_PAGE_FLAG_available	equ	00000001b
ZERO_LONG_MODE_PAGE_FLAG_writeable	equ	00000010b
ZERO_LONG_MODE_PAGE_FLAG_2MiB_size	equ	10000000b
ZERO_LONG_MODE_PAGE_FLAG_default	equ	ZERO_LONG_MODE_PAGE_FLAG_available | ZERO_LONG_MODE_PAGE_FLAG_writeable

zero_long_mode:
	; create the base paging tables for 64-bit mode

	; clear every entry in the tables
	xor	eax,	eax
	mov	ecx,	(0x1000 * 0x06) / 0x04	; PML4 table, PML3 and PML2 four times (1 GiB of mapped space per PML2 table)
	mov	edi,	ZERO_LONG_MODE_PML4_address
	rep	stosd

	; fill the first row of the PML4 table with the PML3 table address (default flags)
	mov	dword [ZERO_LONG_MODE_PML4_address],	ZERO_LONG_MODE_PML4_address + 0x1000 + ZERO_LONG_MODE_PAGE_FLAG_default

	; fill the 4 rows of the PML3 table with the PML2 table addresses (default flags)
	mov	dword [ZERO_LONG_MODE_PML4_address + 0x1000],	ZERO_LONG_MODE_PML4_address + (0x1000 * 0x02) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [ZERO_LONG_MODE_PML4_address + 0x1000 + 0x08],	ZERO_LONG_MODE_PML4_address + (0x1000 * 0x03) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [ZERO_LONG_MODE_PML4_address + 0x1000 + 0x10],	ZERO_LONG_MODE_PML4_address + (0x1000 * 0x04) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [ZERO_LONG_MODE_PML4_address + 0x1000 + 0x18],	ZERO_LONG_MODE_PML4_address + (0x1000 * 0x05) + ZERO_LONG_MODE_PAGE_FLAG_default

	; fill every row of the PML2 tables (default flags + each entry maps 2 MiB of physical address space)
	mov	eax,	ZERO_LONG_MODE_PAGE_FLAG_default + ZERO_LONG_MODE_PAGE_FLAG_2MiB_size	; flags: 2 MiB page size, writable, present
	mov	ecx,	512 * 0x04	; 512 rows per PML2 table
	mov	edi,	ZERO_LONG_MODE_PML4_address + (0x1000 * 0x02)

.next:
	; configure the entry
	stosd

	; advance the pointer to the next table row
	add	edi,	0x04	; each entry is 8 bytes (64-bit mode)

	; map the next 2 MiB of physical address space
	add	eax,	0x00200000

	; rows left to fill?
	dec	ecx
	jnz	.next	; yes

	; load the global descriptor table for 64-bit mode
	lgdt	[zero_long_mode_header_gdt_64bit]

	; enable the NX/PAE, PGE and OSFXSR bits in CR4
	mov	eax,	1010100000b	; NX (bit 5) - no-execute page protection or physical memory addressing up to 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - paging support
					; OSFXSR (bit 9) - support for the XMM0-15 registers

	; load the physical address of the boot program PML4 table into CR3
	mov	eax,	ZERO_LONG_MODE_PML4_address
	mov	cr3,	eax

	; enable LME mode (bit 9) in the EFER MSR
	mov	ecx,	0xC0000080	; EFER MSR address
	rdmsr
	or	eax,	100000000b
	wrmsr

	; enable the PE and PG bits in CR0
	mov	eax,	cr0
	or	eax,	0x80000001	; PE (bit 0) - leave real mode,
	mov	cr0,	eax		; PG (bit 31) - sharing of the paging tables

	; jump to the 64-bit boot program code
	jmp	0x0008:zero_long_mode_entry

; all tables sit at an address aligned to 0x08 bytes
align 0x08
zero_long_mode_table_gdt_64bit:
	; null descriptor
	dq	0x0000000000000000
	; code descriptor
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; data descriptor
	dq	0000000000100000100100100000000000000000000000000000000000000000b
zero_long_mode_table_gdt_64bit_end:

zero_long_mode_header_gdt_64bit:
	dw	zero_long_mode_table_gdt_64bit_end - zero_long_mode_table_gdt_64bit - 0x01
	dd	zero_long_mode_table_gdt_64bit

; 64-bit boot program code ==========================================
[bits 64]

zero_long_mode_entry:
