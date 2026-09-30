
; input:
;	rbx - number of characters in the string
;	rsi - pointer to the string
; output:
;	rax - integer value
library_string_to_integer:
	; preserve the original registers
	push rbx
	push rcx
	push rdx
	push rsi
	push r8
	push rax

	; digit base
	mov ecx, 1

	; partial result
	xor r8, r8

.loop:
	; fetch the last digit from the string
	movzx eax, byte [rsi + rbx - 0x01]
	sub al, STATIC_SCANCODE_DIGIT_0 ; turn the digit's ASCII code into a value
	mul rcx ; convert the digit from its number base

	; fold it into the partial result
	add r8, rax

	; step the base up to tens, hundreds, thousands... and so on
	mov eax, STATIC_NUMBER_SYSTEM_decimal
	mul rcx
	mov rcx, rax

	; end of string?
	dec rbx
	jnz .loop ; no, keep processing

	; return the result
	mov qword [rsp], r8

	; restore the original registers
	pop rax
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rbx

	; return from the procedure
	ret

	macro_debug "library_string_to_integer"
