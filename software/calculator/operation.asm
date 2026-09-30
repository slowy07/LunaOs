
calculator_operation_insert:
 ; save the original registers
 push rax
 push rcx
 push rsi

 ; compose both values if they exist
 call calculator_operation_compose

 ; has the first value been entered?
 cmp r11b, STATIC_TRUE
 je .first_exist ; yes

 ; accept the first value

 ; convert the string entered by the user into a floating point value
 movzx ecx, byte [calculator_window.element_label_value_length]
 mov rsi, calculator_window.element_label_value_string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_to_float

 ; save the value and raise the flag
 mov qword [calculator_value_first], rax
 mov r11b, STATIC_TRUE

 ; end of the operation
 jmp .end

.first_exist:
 ; accept the second value

 ; convert the string entered by the user into a floating point value
 movzx ecx, byte [calculator_window.element_label_value_length]
 mov rsi, calculator_window.element_label_value_string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_to_float

 ; save the value and raise the flag
 mov qword [calculator_value_second], rax
 mov r12b, STATIC_TRUE

.end:
 ; restore the original registers
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

 ; debug
 macro_debug "software: calculator_operation_insert"

; entry:
;	byte [calculator_value_exec]
;	qword [calculator_value_first]
;	qword [calculator_value_second]
; exit:
;	qword [calculator_value_first]
calculator_operation_compose:
 ; have the criteria been met?

 ; has the operation type been chosen?
 cmp byte [calculator_value_exec], STATIC_EMPTY
 je .no_result ; no

 ; the first value has been loaded
 cmp r11b, STATIC_FALSE
 je .no_result ; no

 ; has the second value been loaded?
 cmp r12b, STATIC_FALSE
 je .no_result ; no


 finit ; reset the coprocessor
 fld qword [calculator_value_first]
 fld qword [calculator_value_second]

 ; addition operation?
 cmp byte [calculator_value_exec], "+"
 jne .no_add ; no

 ; perform the operation
 fadd

 ; end of the operation
 jmp .result

.no_add:
 ; subtraction operation?
 cmp byte [calculator_value_exec], "-"
 jne .no_sub ; no

 ; perform the operation
 fsub

 ; end of the operation
 jmp .result

.no_sub:
 ; multiplication operation?
 cmp byte [calculator_value_exec], "*"
 jne .no_multiply ; no

 ; perform the operation
 fmul

 ; end of the operation
 jmp .result

.no_multiply:
 ; multiplication operation?
 cmp byte [calculator_value_exec], "/"
 jne .no_result ; no

 ; perform the operation
 fdiv

.result:
 ; return the result in the first floating point value
 fst qword [calculator_value_first]

 ; the second value has expired
 mov r12b, STATIC_FALSE

.no_result:
 ; return from the procedure
 ret

 ; debug
 macro_debug "software: calculator_operation_compose"

; entry:
;	ax - value from the keyboard or the mouse
calculator_operation:
 ; save the original registers
 push rax
 push rsi

 ; the processed string and its size
 movzx ecx, byte [calculator_window.element_label_value_length]
 mov rsi, calculator_window.element_label_value_string

 ; modification of the value?
 cmp ax, STATIC_SCANCODE_DIGIT_0
 jb .no_digit ; no
 cmp ax, STATIC_SCANCODE_DIGIT_9
 ja .no_digit ; no

.dot:
 ; comma?
 cmp ax, ","
 jne .not_dot ; no

 ; has the comma already been inserted?
 test r10b, r10b
 jz .error ; yes, ignore

 ; mark with a flag the insertion of a comma into the number
 mov r10b, STATIC_TRUE

 ; is the first and only digit of the value a ZERO?
 cmp byte [calculator_window.element_label_value_length], STATIC_BYTE_SIZE_byte
 jne .not_dot ; no
 cmp byte [calculator_window.element_label_value_string], STATIC_SCANCODE_DIGIT_0
 jne .not_dot ; no

 ; do not clear the value
 mov r13b, STATIC_FALSE

.not_dot:
 ; has the input limit been reached?
 cmp cl, CALCULATOR_INPUT_VALUE_WIDTH_char
 jnb .error ; yes, ignore the digit

 ; clear the value before appending a digit/comma?
 cmp r13b, STATIC_FALSE
 je .empty ; no

 ; clear the flag
 mov r13b, STATIC_FALSE

 ; reset the size of the value string
 xor cl, cl
 mov byte [calculator_window.element_label_value_length], STATIC_EMPTY

.empty:
 ; does the user want to insert the ZERO digit?
 cmp al, STATIC_SCANCODE_DIGIT_0
 jne .not_zero ; no

 ; at the beginning of the value string?
 test cl, cl
 jz .error ; yes

.not_zero:
 ; append the digit to the end of the string
 mov byte [rsi + rcx], al

 ; size of the string
 inc byte [calculator_window.element_label_value_length]

 ; the operation has been performed
 clc

 ; the operation has been executed
 jmp .end

.error:
 ; the operation has not been performed
 stc

 ; end of the procedure
 jmp .end

.no_digit:
 ; sum of the operations?
 cmp ax, "+"
 je .add ; yes

 ; difference of the operations?
 cmp ax, "-"
 je .sub ; yes

 ; product of the operations?
 cmp ax, "*"
 je .multiply ; yes

 ; quotient of the operations?
 cmp ax, "/"
 je .divide ; yes

 ; insert the fractional part?
 cmp ax, ","
 je .dot ; yes

 ; process it?
 cmp ax, "="
 je .result ; yes

 ; step the value back?
 cmp ax, STATIC_SCANCODE_BACKSPACE
 je .backspace ; yes

 ; process it?
 cmp ax, STATIC_SCANCODE_RETURN
 jne .error ; no

.result:
 ; load the value into the variable
 call calculator_operation_insert
 jc .end ; no value passed

 ; compose both values if they exist
 call calculator_operation_compose

 ; save the operation character
 mov byte [calculator_value_exec], "="

 ; end of the operation handling
 jmp .preserve

.backspace:
 ; does the value string contain only a single digit/comma?
 cmp cl, STATIC_BYTE_SIZE_byte
 jne .backspace_prepare ; no

 ; replace the first digit with a ZERO
 mov byte [calculator_window.element_label_value_string], STATIC_SCANCODE_DIGIT_0

 ; end of the operation handling
 jmp .preserve

.backspace_prepare:
 ; remove the last digit (or the comma) from the string
 dec cl

 ; is the removed character a comma?
 cmp byte [rsi + rcx], ","
 jne .backspace_ready ; no

 ; release the comma flag
 mov r10b, STATIC_FALSE

.backspace_ready:
 ; update the size of the string
 mov byte [calculator_window.element_label_value_length], cl

 ; end of the operation handling
 jmp .end

.add:
 ; load the value into the variable
 call calculator_operation_insert
 jc .end ; no value passed

 ; save the operation character
 mov byte [calculator_value_exec], "+"

 ; clear the value before modifying it
 mov r13b, STATIC_TRUE

 ; end of the procedure
 jmp .preserve

.sub:

.multiply:

.divide:
 ; end of the operation handling
 jmp .end

.preserve:
 ; clear the value before modifying it
 mov r13b, STATIC_TRUE

.end:
 ; restore the original registers
 pop rsi
 pop rax

 ; return from the procedure
 ret

 ; debug
 macro_debug "software: calculator_operation"
