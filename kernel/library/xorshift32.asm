;===============================================================================

;===============================================================================
; input:
;	rax - seed
; output:
;	rax - "random" value
library_xorshift32:
	; preserve the original registers
	push	rdx

	; https://en.wikipedia.org/wiki/Xorshift
	mov	edx,	eax
	shl	eax,	13
	xor	eax,	edx
	mov	edx,	eax
	shr	eax,	17
	xor	eax,	edx
	mov	edx,	eax
	shl	eax,	5
	xor	eax,	edx

	; restore the original registers
	pop	rdx

	; return from the procedure
	ret

	macro_debug	"library_xorshift32"
