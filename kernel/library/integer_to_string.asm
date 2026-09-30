
; input:
;	rax - integer value
;	rbx - number base (base: 2..36)
;	rcx - number of characters in the prefix
;	dl - prefix ASCII code
;	rdi - destination string pointer
; output:
;	CF flag, if the base is invalid
;	rcx - number of processed digits
library_integer_to_string:
	; preserve the original registers
	push	rax
	push	rdx
	push	rdi
	push	rbp
	push	r9
	push	rcx

	; number base supported?
	cmp	rbx,	2
	jb	.error	; no
	cmp	rbx,	36
	ja	.error	; no

	; store the prefix value
	mov	r9,	rdx

	; clear the high part / remainder
	xor	rdx,	rdx

	; create a stack of local variables
	mov	rbp,	rsp

.loop:
	; compute the remainder
	div	rbx

	; store the remainder in the local variables
	add	rdx,	STATIC_SCANCODE_DIGIT_0	; convert the digit into an ASCII code
	push	rdx

	; shrink the prefix size
	dec	rcx

	; clear the remainder
	xor	rdx,	rdx

	; keep converting?
	test	rax,	rax
	jnz	.loop	; yes

	; fill the prefix?
	cmp	rcx,	STATIC_EMPTY
	jle	.init	; no

.prefix:
	; fill the value with the prefix
	push	r9

	; keep filling?
	dec	rcx
	jnz	.prefix	; yes

.init:
	; number of processed digits
	xor	ecx,	ecx

.return:
	; any digits left to display?
	cmp	rsp,	rbp
	je	.end	; no

	; fetch the digit
	pop	rax

	; check whether the number base is above 10
	cmp	al,	0x3A
	jb	.no	; if not, continue

	; fix the ASCII code up to the matching number base
	add	al,	0x07

.no:
	; return the digit
	stosb

	; processed digit
	inc	rcx

	; continue
	jmp	.return

.error:
	; flag, error
	stc

.end:
	; return information about the number of processed digits
	mov	qword [rsp],	rcx

	; restore the original registers
	pop	rcx
	pop	r9
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_integer_to_string"
