;===============================================================================

;===============================================================================
; input:
;	rcx - number of characters in the string
;	rsi - pointer to the string
; output:
;	CF flag - if the string does not contain only digits
library_string_digits:
	; preserve the original registers
	push	rsi
	push	rcx

.loop:
	; character outside the digit range?
	cmp	byte [rsi],	STATIC_SCANCODE_DIGIT_0
	jb	.error	; yes
	cmp	byte [rsi],	STATIC_SCANCODE_DIGIT_9
	ja	.error	; yes

	; check the next character
	inc	rsi

	; end of string
	dec	rcx
	jnz	.loop	; no

	; flag, success
	clc

	; end of procedure
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rcx
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"library_string_digits"
