;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/calculator/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
calculator:
	; initialization of the console space
	%include	"software/calculator/init.asm"

.reset:
	; flag, comma
	mov	r10b,	STATIC_FALSE	; a fractional part character has been entered

	; flag, the first and the second value
	mov	r11b,	STATIC_FALSE	; the first value has been confirmed
	mov	r12b,	STATIC_FALSE	; the second value has been confirmed

	; flag, increment
	mov	r13b,	STATIC_TRUE	; clear the value before modifying it

	; flag, value character
	mov	r14b,	STATIC_FALSE	; positive

	; clear the contents of the labels
	mov	byte [calculator_window.element_label_operation_string],	STATIC_SCANCODE_SPACE
	mov	byte [calculator_window.element_label_value_string],	STATIC_SCANCODE_DIGIT_0
	mov	byte [calculator_window.element_label_value_length],	STATIC_BYTE_SIZE_byte

.refresh:
	; display the result/state of the last operation
	call	calculator_show

	; update the contents of the labels
	mov	rdi,	calculator_window

	; operation label
	mov	rsi,	calculator_window.element_label_operation
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; value label
	mov	rsi,	calculator_window.element_label_value
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; update the window contents
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	calculator_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

.loop:
	; fetch the message
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	calculator_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; no message

	; message of the pointing device (mouse) type?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	je	.mouse	; yes

	; message of the pointing device (keyboard) type?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.loop	; no, ignore the key

	; fetch the key code
	mov	ax,	word [rdi + KERNEL_IPC_STRUCTURE.data]

.operation:
	; restart all the operations?
	cmp	ax,	STATIC_SCANCODE_ESCAPE
	je	.reset	; yes

	; perform the operation bound to the key
	call	calculator_operation
	jc	.loop	; no actions

	; return to the procedure
	jmp	.refresh

.mouse:
	; left mouse button press?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event],	KERNEL_IPC_MOUSE_EVENT_left_press
	jne	.loop	; no, ignore the message

	; fetch the cursor coordinates
	movzx	r8d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.x]	; x
	movzx	r9d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.y]	; y

	; fetch the pointer to the element taking part in the event
	mov	rsi,	calculator_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element
	jc	.loop	; the dependent element was not found

	; an element of the "Button Close" type?
	cmp	byte [rsi],	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	je	.close	; yes

	; fetch the value of the element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]

	; perform the operation
	jmp	.operation

.close:
	; terminate the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: calculator"

	;-----------------------------------------------------------------------
	%include	"software/calculator/data.asm"
	%include	"software/calculator/operation.asm"
	%include	"software/calculator/show.asm"
	%include	"software/calculator/fpu.asm"
	;-----------------------------------------------------------------------
