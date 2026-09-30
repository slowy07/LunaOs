
zero_memory:
	; begin mapping from the start of the physical memory space
	xor	ebx,	ebx

	; the "SMAP" string, a special value the routine requires
	mov	edx,	0x534D4150

	; build the memory map at physical address 0x0000:0x1000
	mov	edi,	zero_end
	call	zero_page_align_up

	; store the address for the kernel
	mov	dword [zero_memory_map_address],	edi

.loop:
	; fetch information about the memory space
	mov	eax,	0xE820	; funkcja Get System Memory Map
	mov	ecx,	0x14	; entry size in bytes of the generated table
	int	0x15

.error:
	; error during generation?
	jc	.error	; yes

	; advance the pointer to the next entry
	add	edi,	0x14

	; finished generating the table?
	test	ebx,	ebx
	jnz	.loop	; no

	; append an empty entry at the end of the table
	xor	al,	al
	rep	stosb
