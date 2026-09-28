;===============================================================================

;===============================================================================
; input:
;	rax - value
; output:
;	rax - value
;	rbx - type
;		0 - Bytes
;		1 - KiB
;		2 - MiB
;		3 - GiB
;		4 - TiB
;		5 - PiB
;		6 - EiB
;		7 - ZiB
;		8 - YiB
;	rdx - percentage of the remainder
library_value_to_size:
	; preserve the original registers
	push	rcx
	push	rax

	; initialise the size
	xor	ebx,	ebx

	; base size divisor
	mov	ecx,	1024

	; default percentage of the remainder
	xor	edx,	edx

	; value smaller than the base?
	cmp	rax,	1024
	jb	.end	; yes, no conversion

.loop:
	; convert the original value into the matching size
	mov	rax,	qword [rsp]
	div	rcx

	; next size of the value
	shl	rcx,	STATIC_MULTIPLE_BY_1024_shift

	; converted to the next size
	inc	bl

	; result value smaller than the base?
	cmp	rax,	1024
	jae	.loop	; yes, convert to another size

	; store the whole result
	mov	qword [rsp],	rax

	; convert the remainder into %
	mov	rax,	rdx
	mov	edx,	100
	shr	rcx,	STATIC_DIVIDE_BY_1024_shift	; fix up the result base
	mul	rdx
	div	rcx

	; return the percentage
	mov	rdx,	rax

.end:
	; restore the original registers
	pop	rax
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"library_value_to_size"
