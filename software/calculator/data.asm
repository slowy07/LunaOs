
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
calculator_fpu_float_result				dq	STATIC_EMPTY
calculator_fpu_precision				dq	STATIC_EMPTY
calculator_fpu_precision_value			dq	10	; a single place after the comma
calculator_fpu_control				dw	0

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
calculator_fpu_integer				dq	0
calculator_fpu_fraction				dq	0

calculator_value_exec				db	STATIC_EMPTY
calculator_value_first				dq	0.0
calculator_value_second				dq	0.0

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
calculator_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
calculator_window:					dw	STATIC_EMPTY	; position on the X axis
						dw	STATIC_EMPTY	; position on the Y axis
						dw	CALCULATOR_WINDOW_WIDTH_pixel	; window width
						dw	CALCULATOR_WINDOW_HEIGHT_pixel	; window height
						dq	STATIC_EMPTY	; pointer to the window data space (filled in by Bosu)
.extra:						dd	STATIC_EMPTY	; size of the window data space in bytes (filled in by Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; window identifier (filled in by Bosu)
						db	5
						db	"Calculator                     "	; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
						dq	STATIC_EMPTY	; window width in bytes (filled in by Bosu)
.elements:					;-------------------------------
						; element "window close"
.element_button_close:				db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	calculator.close
.element_button_close_end:			;-------------------------------
						; element "label operation"
.element_label_operation:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_operation_end - .element_label_operation
						dw	CALCULATOR_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	CALCULATOR_INPUT_OPERATION_WIDTH_pixel
						dw	CALCULATOR_INPUT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
.element_label_operation_length:		db	1
.element_label_operation_string:		db	STATIC_SCANCODE_SPACE
times	CALCULATOR_INPUT_OPERATION_WIDTH_char - 0x01	db	STATIC_EMPTY
.element_label_operation_end:			;-------------------------------
						; element "label value"
.element_label_value:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_value_end - .element_label_value
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_INPUT_OPERATION_WIDTH_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	CALCULATOR_INPUT_VALUE_WIDTH_pixel
						dw	CALCULATOR_INPUT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
.element_label_value_length:			db	1
.element_label_value_string:			db	"0"
times	CALCULATOR_INPUT_VALUE_WIDTH_char - 0x01	db	STATIC_EMPTY
.element_label_value_end:			;-------------------------------
						; element "button C"
.element_button_C:				db	LIBRARY_BOSU_ELEMENT_TYPE_button	; type
						dw	.element_button_C_end - .element_button_C	; size of the element
						dw	CALCULATOR_WINDOW_PADDING_pixel	; x
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel	; y
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel	; width
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel	; height
						dq	STATIC_SCANCODE_ESCAPE	; value held by the element
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1	; number of characters representing the button name
						db	"C"	; string of characters representing the button name
.element_button_C_end:				;-------------------------------
						; element "button 7"
.element_button_7:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_7_end - .element_button_7
						dw	CALCULATOR_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_7
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"7"
.element_button_7_end:				;-------------------------------
						; element "button 4"
.element_button_4:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_4_end - .element_button_4
						dw	CALCULATOR_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_4
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"4"
.element_button_4_end:				;-------------------------------
						; element "button 1"
.element_button_1:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_1_end - .element_button_1
						dw	CALCULATOR_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_1
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"1"
.element_button_1_end:				;-------------------------------
						; element "button 0"
.element_button_0:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_0_end - .element_button_0
						dw	CALCULATOR_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_0
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"0"
.element_button_0_end:				;-------------------------------
						; element "button DIVIDE"
.element_button_DIVIDE:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_DIVIDE_end - .element_button_DIVIDE
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	"/"
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"/"
.element_button_DIVIDE_end:			;-------------------------------
						; element "button 8"
.element_button_8:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_8_end - .element_button_8
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_8
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"8"
.element_button_8_end:				;-------------------------------
						; element "button 5"
.element_button_5:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_5_end - .element_button_5
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_5
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"5"
.element_button_5_end:				;-------------------------------
						; element "button 2"
.element_button_2:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_2_end - .element_button_2
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_2
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"2"
.element_button_2_end:				;-------------------------------
						; element "button MULTIPLY"
.element_button_MULTIPLY:			db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_MULTIPLY_end - .element_button_MULTIPLY
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	"*"
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"*"
.element_button_MULTIPLY_end:			;-------------------------------
						; element "button 9"
.element_button_9:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_9_end - .element_button_9
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_9
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"9"
.element_button_9_end:				;-------------------------------
						; element "button 6"
.element_button_6:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_6_end - .element_button_6
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_6
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"6"
.element_button_6_end:				;-------------------------------
						; element "button 3"
.element_button_3:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_3_end - .element_button_3
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_3
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"3"
.element_button_3_end:				;-------------------------------
						; element "button DOT"
.element_button_DOT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_DOT_end - .element_button_DOT
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	","
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	","
.element_button_DOT_end:			;-------------------------------
						; element "button SUB"
.element_button_SUB:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_SUB_end - .element_button_SUB
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_MINUS
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"-"
.element_button_SUB_end:			;-------------------------------
						; element "button ADD"
.element_button_ADD:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_ADD_end - .element_button_ADD
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dq	"+"
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"+"
.element_button_ADD_end:			;-------------------------------
						; element "button RESULT"
.element_button_RESULT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_RESULT_end - .element_button_RESULT
						dw	CALCULATOR_WINDOW_PADDING_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + CALCULATOR_INPUT_HEIGHT_pixel + CALCULATOR_WINDOW_ELEMENT_MARGIN_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel
						dw	CALCULATOR_WINDOW_ELEMENT_SIZE_pixel + CALCULATOR_WINDOW_ELEMENT_AREA_pixel
						dq	STATIC_SCANCODE_RETURN
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"="
.element_button_RESULT_end:			;-------------------------------
						; end of the window elements
						db	STATIC_EMPTY
calculator_window_end:
