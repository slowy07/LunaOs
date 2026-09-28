;===============================================================================

;===============================================================================
; input:
;	rsi - start of the binary memory map region
;	rdi - end of the binary memory map region
; output:
;	CF flag - error, if set
;	rax - absolute index of the found bit
library_bit_find:
	; preserve the original registers
	push	rcx
	push	rdi
	push	rsi

	; clear the accumulator
	xor	eax,	eax

.search:
	; check whether the "packet" holds any bits at all
	cmp	qword [rsi],	STATIC_EMPTY
	jne	.found	; found

	; check the next "packet"
	add	rsi,	STATIC_QWORD_SIZE_byte

	; check whether the whole binary map has been searched
	cmp	rsi,	rdi
	jne	.search	; keep searching

	; flag, error
	stc

	; end
	jmp	.end

.found:
	; todo:
	; tzcnt

	; fetch the free bit position counting from the oldest bit in the word and clear it
	bsf	rax,	qword [rsi]
	btr	qword [rsi],	rax

	; compute the absolute index of the taken bit
	sub	rsi,	qword [rsp]

	; convert bytes to bits
	shl	rsi,	STATIC_DIVIDE_BY_8_shift

	; return the sum of the positions
	add	rax,	rsi

	; flag, success
	clc

.end:
	; restore the original registers
	pop	rsi
	pop	rdi
	pop	rcx

	; return from the procedure
	ret
