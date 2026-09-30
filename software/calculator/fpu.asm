
; entry:
;	qword [calculator_fpu_precision] - number of places after the comma
;	qword [calculator_fpu_fraction] - value of the fraction in integer form
; exit:
;	qword [calculator_fpu_float_result] - floating point value
calculator_fpu_fraction_to_float:
	finit ; reset the coprocessor
	fld1 ; st2
	fild qword [calculator_fpu_precision_value] ; st1
	fild qword [calculator_fpu_fraction] ; st0

.loop:
	; convert to a fraction?
	dec qword [calculator_fpu_precision]
	js .end ; no
	jz .ready ; end

	; convert the number into a fraction
	fdiv st0, st1
	jmp .loop ; continue

.ready:
	; save the result of the conversion operation
	fstp qword [calculator_fpu_float_result]

.end:
	; return from the procedure
	ret

; entry:
;	qword [calculator_fpu_precision] - number of digits to interpret
;	qword [calculator_fpu_float_result] - integer part of the floating point value (integer.float)
; exit:
;	qword [calculator_fpu_fraction] - integer part of the FLOATING POINT value
calculator_fpu_float_to_fraction:
	; save the original registers/variables
	push rcx

	; fetch the precision size
	mov rcx, qword [calculator_fpu_precision]

	; remove the integer part
	call calculator_fpu_float_only

	finit ; reset the coprocessor
	fild qword [calculator_fpu_precision_value]
	fld qword [calculator_fpu_float_result]

.loop:
	; convert to a fraction?
	dec rcx
	js .end ; no
	jz .ready ; end

	; convert the fraction into a number
	fmul st0, st1
	jmp .loop ; continue

.ready:
	fistp qword [calculator_fpu_fraction]

.end:
	; restore the original registers
	pop rcx

	; return from the procedure
	ret

; entry:
;	qword [calculator_fpu_float_result] - floating point value (integer.float)
; exit:
;	qword [calculator_fpu_integer] - integer part of the floating point value (integer)
calculator_fpu_float_to_integer:
	finit ; reset the coprocessor
	fldcw word [calculator_fpu_control] ; load the coprocessor flags from the variable
	fld qword [calculator_fpu_float_result]
	fistp qword [calculator_fpu_integer]

	; return from the procedure
	ret

; entry:
;	qword [calculator_fpu_integer] - integer value (integer)
; exit:
;	qword [calculator_fpu_float_result] - floating point value (integer.0)
calculator_fpu_integer_to_float:
	finit ; reset the coprocessor
	fild qword [calculator_fpu_integer]
	fst qword [calculator_fpu_float_result]

	; return from the procedure
	ret

; entry:
;	qword [calculator_fpu_float_result] - integer part of the floating point value
; exit:
;	qword [calculator_fpu_float_result] - floating point value (0.float)
calculator_fpu_float_only:
	; save the original variables
	push qword [calculator_fpu_integer]

	; store the integer part of the floating point value separately
	call calculator_fpu_float_to_integer

	finit ; reset the coprocessor
	fld qword [calculator_fpu_float_result]
        fisub dword [calculator_fpu_integer]
        fstp qword [calculator_fpu_float_result]

	; restore the original variables
	pop qword [calculator_fpu_integer]

	; return from the procedure
	ret
