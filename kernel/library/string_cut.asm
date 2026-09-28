;===============================================================================

;===============================================================================
; input:
;	al - separator
;	rcx - number of characters in the string
;	rsi - pointer to the string
; output:
;	CF flag - no separator
;	rcx - number of characters in the word
library_string_cut:
	; preserve the original registers
	push	rsi
	push	rcx

.loop:
	; end of string?
	cmp	byte [rsi],	STATIC_SCANCODE_TERMINATOR
	je	.end	; yes

	; separator found
	cmp	byte [rsi],	al
	je	.end	; yes, end of procedure

	; increment the counter and check the next character
	inc	rsi

	; check the next character of the string?
	dec	rcx
	jnz	.loop

	; flag, error
	stc

.end:
	; return the number of characters in the word
	sub	qword [rsp],	rcx

	; restore the original registers
	pop	rcx
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"library_string_cut"
