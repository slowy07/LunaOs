
%macro	macro_lock	2
	push	rax

.1:	; close access to %1
	mov	al,	STATIC_TRUE
%ifidn	%1,	rbx
	xchg	byte [%1 + %2],	al
%else
	xchg	byte [rel %1 + %2],	al
%endif
	test	al,	al
	jz	.1	; try once more

	pop	rax
%endmacro
