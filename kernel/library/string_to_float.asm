
; input:
;	rcx - number of characters in the string
;	rsi - pointer to the string
; output:
;	rax - floating point value
library_string_to_float:
	; preserve the original registers
	push rbx
	push rcx
	push rsi
	push rax

	; empty string?
	test rcx, rcx
	jz .error ; yes

	; set up the local variables
	push STATIC_NUMBER_SYSTEM_decimal ; decimal system
	push STATIC_EMPTY ; fraction
	push STATIC_EMPTY ; integer part

	; look for the fraction character in the string
	mov al, ","
	call library_string_word_next
	jnc .integer ; convert the integer value into the fractional part

	; convert the whole string to a number
	call library_string_to_integer

	; update the integer part
	mov qword [rsp], rax

	; integer part as a float
	finit ; reset the coprocessor
	fild qword [rsp]

	; free the local variables
	add rsp, STATIC_QWORD_SIZE_byte * 0x03

	; return the result
	fstp qword [rsp]

	; end of the conversion
	jmp .end

.integer:
	; number of digits in the integer part
	test rbx, rbx
	jz .integer_empty ; none

	; convert the whole string to a number
	call library_string_to_integer

	; update the integer part
	mov qword [rsp], rax

.integer_empty:
	; fix up the string size and pointer
	inc rbx ; separator
	sub rcx, rbx
	add rsi, rbx

.fraction:
	; no fractional part by default
	xor ebx, ebx

	; no digits in the fraction value?
	test rcx, rcx
	jz .transform ; yes

	; convert the whole string to a number
	mov rbx, rcx
	call library_string_to_integer

	; update the fraction value
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rax

.transform:
	; fraction value as a float
	finit ; reset the coprocessor
	fild qword [rsp + STATIC_QWORD_SIZE_byte * 0x02] ; st1 > number base
	fild qword [rsp + STATIC_QWORD_SIZE_byte] ; st0 > fraction

.convert:
	; convert the number into a fraction
	fdiv st0, st1 ; divide by st1

	; magnitude reached?
	dec rbx
	jnz .convert ; no, keep converting

	; sum the two floating point values
	fild qword [rsp] ; st0 > integer part
	faddp st1, st0

	; free the local variables
	add rsp, STATIC_QWORD_SIZE_byte * 0x03

	; return the result
	fstp qword [rsp]

	; end of the conversion
	jmp .end

.error:
	; the string could not be processed correctly, return "0.0"
	mov qword [rsp], STATIC_EMPTY

.end:
	; restore the original registers
	pop rax
	pop rsi
	pop rcx
	pop rbx

	; return from the procedure
	ret

	macro_debug "library_string_to_float"
