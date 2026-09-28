;===============================================================================

%MACRO	macro_library	1
	; zachowaj wartość procesu
	push	rbp

	; odłóż na stos adres procedury docelowej
	mov	rbp,	LIBRARY_BASE_address + %1
	call	qword [rbp]	; wykonaj skok do biblioteki

	; przywróć wartość procesu
	pop	rbp
%ENDMACRO
