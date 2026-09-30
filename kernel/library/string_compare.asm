
; input:
;	rcx - number of characters to compare
;	rsi - pointer to the first string
;	rdi - pointer to the second string
; output:
;	CF flag - if different
library_string_compare:
	; preserve the original registers
	push rax
	push rcx
	push rsi
	push rdi

.loop:
	; load the character from the RSI string into the AL register, bump RSI by 1
	lodsb

	; check whether the character matches the one from the second string
	cmp al, byte [rdi]
	jne .error ; different

	; advance the RDI string pointer to the next position
	inc rdi

	; continue while further characters remain to compare
	dec rcx
	jnz .loop

	; flag, success
	clc

	; end of procedure
	jmp .end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop rdi
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "library_string_compare"
