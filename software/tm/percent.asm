;===============================================================================

;===============================================================================
; entry:
;	rax - value
tm_percent:
	; save the original registers
	push	rcx
	push	rdx
	push	r8
	push	r9
	push	r10
	push	rax

	; fetch the RAM space information
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; convert the value into a percentage without the remainder
	mov	rax,	qword [rsp]
	xor	edx,	edx
	mov	rcx,	100
	mul	rcx
	div	r8

	; return the result
	mov	qword [rsp],	rax

	; restore the original registers
	pop	rax
	pop	r10
	pop	r9
	pop	r8
	pop	rdx
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"software: tm_percent"
