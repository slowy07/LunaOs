
; input:
;	al - separator ASCII code
;	rcx - string size in bytes
;	rsi - pointer to the string
; output:
;	CF flag - if no separator was found
;	rbx - string size up to the first separator
;	or rbx = rcx if the CF flag is set
library_string_word_next:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi

	; counter
	xor	ebx,	ebx

.search:
	; end of string?
	dec	rcx
	js	.not_found	; yes

	; separator found?
	cmp	byte [rsi],	al
	je	.end	; yes, end of the string chunk

	; move the pointer to the next character in the command buffer
	inc	rsi

	; increment the counter of characters belonging to the found word
	inc	rbx

	; keep counting
	jmp	.search

.not_found:
	; no word found in the character string
	stc

.end:
	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_string_word_next"
