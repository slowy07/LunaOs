
; exit:
;	bx - pattern of the drawn block
tetris_random_block:
	; save the original registers
	push	rax
	push	rdx

	; fetch the current time
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; modify the seed by the current system uptime
	add	dword [tetris_seed],	eax

	; fetch a pseudo random value
	mov	eax,	dword [tetris_seed]
	macro_library	LIBRARY_STRUCTURE_ENTRY.xorshift32

	; save the result as the next seed
	mov	dword [tetris_seed],	eax

	; return a value from the range of the number of available blocks
	div	qword [tetris_limit]

	; return the result
	mov	rbx,	tetris_bricks
	mov	rbx,	qword [rbx + rdx * STATIC_QWORD_SIZE_byte]
	call	tetris_random_model	; choose one of the possible patterns

	; remove the remaining patterns from memory
	and	rbx,	STATIC_WORD_mask

	; restore the original registers
	pop	rdx
	pop	rax

	; return from the procedure
	ret

; entry:
;	bx - drawn block
; exit:
;	bx - one of the patterns of the drawn block
tetris_random_model:
	; save the original registers
	push	rax
	push	rcx
	push	rdx

	; fetch a pseudo random value
	mov	eax,	dword [tetris_seed]
	macro_library	LIBRARY_STRUCTURE_ENTRY.xorshift32

	; return a value from the range of the number of available patterns
	div	qword [tetris_limit_model]

	; modify
	shl	rdx,	STATIC_MULTIPLE_BY_16_shift
	mov	cl,	dl
	ror	rbx,	cl

	; restore the original registers
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret
