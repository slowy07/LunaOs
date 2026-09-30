
; input:
;	rcx - number of characters in the string
;	rsi - pointer to the string
; output:
;	CF flag - empty string
;	rcx - number of characters in the string without the "white" characters
;	rsi - pointer to the start of the string without the "white" characters
library_string_trim:
	; preserve the original registers
	push rcx
	push rsi

	; empty string?
	test rcx, rcx
	jz .error ; yes

.prefix:
	; space?
	cmp byte [rsi], STATIC_SCANCODE_SPACE
	je .prefix_found ; yes

	; tab?
	cmp byte [rsi], STATIC_SCANCODE_TAB
	je .prefix_found ; yes

	; empty character?
	cmp byte [rsi], STATIC_EMPTY
	jne .prefix_ready ; no

.prefix_found:
	; move the pointer to the next character in the string
	inc rsi

	; number of characters in the string
	dec rcx
	jnz .prefix ; process the remaining string content

	; empty string
	jmp .error

.prefix_ready:
	; move the pointer to the end of the string
	add rsi, rcx

.suffix:
	; space?
	cmp byte [rsi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_SPACE
	je .suffix_found ; yes

	; tab?
	cmp byte [rsi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_TAB
	je .suffix_found ; yes

	; empty character?
	cmp byte [rsi - STATIC_BYTE_SIZE_byte], STATIC_EMPTY
	jne .suffix_ready ; no

.suffix_found:
	; move the pointer to the previous character in the string
	dec rsi

	; number of characters in the string
	dec rcx
	jnz .suffix ; process the remaining string content

	; empty string
	jmp .error

.suffix_ready:
	; set the pointer to the start of the string without the "white" characters
	sub rsi, rcx

	; return the properties of the new string
	mov qword [rsp], rsi
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx

	; flag, success
	clc

	; end of procedure
	jmp .end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop rsi
	pop rcx

	; return from the procedure
	ret

	macro_debug "library_string_trim"
