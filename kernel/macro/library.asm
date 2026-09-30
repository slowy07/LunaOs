
%MACRO	macro_library	1
	; preserve the frame pointer
	push	rbp

	; store the address of the target routine on the stack
	mov	rbp,	LIBRARY_BASE_address + %1
	call	qword [rbp]	; jump into the library

	; restore the frame pointer
	pop	rbp
%ENDMACRO
