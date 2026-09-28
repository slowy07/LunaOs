;===============================================================================

%macro	macro_lock	2
	push	rax

.1:	; zamknij dostęp do %1
	mov	al,	STATIC_TRUE
%ifidn	%1,	rbx
	xchg	byte [%1 + %2],	al
%else
	xchg	byte [rel %1 + %2],	al
%endif
	test	al,	al
	jz	.1	; spróbuj raz jeszczy

	pop	rax
%endmacro
