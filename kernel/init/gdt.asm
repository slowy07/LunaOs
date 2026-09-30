
struc	KERNEL_STRUCTURE_GDT_HEADER
	.limit						resb	2
	.address					resb	8
endstruc

struc	KERNEL_STRUCTURE_GDT
	.null						resb	8
	.cs_ring0					resb	8
	.ds_ring0					resb	8
	.cs_ring3					resb	8
	.ds_ring3					resb	8
	.tss						resb	8
	.SIZE:
endstruc

kernel_init_gdt:
	; reserve room for the Global Descriptor Table
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; clear the GDT table and save its address
	call	kernel_page_drain
	mov	qword [rel kernel_gdt_header + KERNEL_STRUCTURE_GDT_HEADER.address],	rdi

	; create the NULL descriptor
	xor	eax,	eax
	stosq	; store

	; create the ring0 code descriptor (CS)
	mov	rax,	0000000000100000100110000000000000000000000000000000000000000000b
	stosq	; store

	; create the ring0 data/stack descriptor (DS/SS)
	mov	rax,	0000000000100000100100100000000000000000000000000000000000000000b
	stosq	; store

	; create the ring3 code descriptor (CS)
	mov	rax,	0000000000100000111110000000000000000000000000000000000000000000b
	stosq	; store

	; create the ring3 data/stack descriptor (DS/SS)
	mov	rax,	0000000000100000111100100000000100000000000000000000000000000000b
	stosq	; store

	; save the indirect address of the first TSS descriptor
	and	di,	~STATIC_PAGE_mask
	mov	word [rel kernel_gdt_tss_bsp_selector],	di

	; create N TSS descriptors for the logical processors
	mov	cx,	word [rel kernel_apic_count]
	mov	rsi,	kernel_apic_id_table

.loop:
	; fetch the logical processor identifier
	lodsb

	; turn it into a descriptor
	and	eax,	STATIC_BYTE_mask
	shl	eax,	STATIC_MULTIPLE_BY_16_shift

	; point at the target TSS descriptor of the logical processor
	mov	rdi,	qword [rel kernel_gdt_header + KERNEL_STRUCTURE_GDT_HEADER.address]
	add	rdi,	rax
	add	di,	word [rel kernel_gdt_tss_bsp_selector]

	; size of the Task State Segment table in bytes
	mov	ax,	kernel_gdt_tss_table_end - kernel_gdt_tss_table
	stosw	; store

	; fetch the physical address of the Task State Segment table
	mov	rax,	kernel_gdt_tss_table
	stosw	; store (bits 15..0)
	shr	rax,	16	; shift the high part of the EAX register into AX
	stosb	; store (bits 23..16)

	; save the remaining part of the Task State Segment table address
	push	rax

	; fill in the Task State Segment descriptor with the flags
	mov	al,	10001001b	; P, DPL, 0, Type
	stosb	; store
	xor	al,	al		; G, 0, 0, AVL, Limit (high part of the Task State Segment table size)
	stosb	; store

	; restore the remaining part of the Task State Segment table address
	pop	rax

	; move bits 31..24 into the AL register
	shr	rax,	8
	stosb	; store (bits 31..24)

	; move bits 63..32 into the EAX register
	shr	rax,	8
	stosd	; store (bits 63..32)

	; 32 descriptor bytes - reserved
	xor	rax,	rax
	stosd	; store

	; create the rest?
	dec	cx
	jnz	.loop	; yes

	; reload the Global Descriptor Table
	lgdt	[rel kernel_gdt_header]

	; load the Task State Segment descriptor
	ltr	word [rel kernel_gdt_tss_bsp_selector]

	; reset the unused descriptors
	mov	fs,	ax
	mov	gs,	ax

	; reload the main descriptors
	mov	ax,	KERNEL_STRUCTURE_GDT.ds_ring0
	mov	ds,	ax	; data
	mov	es,	ax	; extra
	mov	ss,	ax	; stack
